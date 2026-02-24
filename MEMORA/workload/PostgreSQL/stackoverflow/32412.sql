
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM 
        UserStatistics us
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        p.Title AS PostTitle,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM 
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
RecentActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 11 
    GROUP BY 
        p.Id, p.Title, p.CreationDate
    HAVING 
        COUNT(c.Id) > 0
)
SELECT 
    rp.PostId,
    rp.Title AS PostTitle,
    rup.DisplayName AS TopUser,
    rup.Reputation AS UserReputation,
    p.CommentCount AS CommentsCount,
    ph.Comment AS UserComment,
    ph.CreationDate AS CommentDate,
    ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY ph.CreationDate DESC) AS RecentCommentRank
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers rup ON rp.OwnerUserId = rup.UserId
LEFT JOIN 
    RecentActivePosts p ON rp.PostId = p.PostId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.CommentRank = 1
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.PostTypeId, rp.Score DESC;
