WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
),
FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId AND ph.PostHistoryTypeId = 10
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, b.Name
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    fu.UserId,
    fu.DisplayName,
    fu.Reputation,
    fu.BadgeName,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    pa.CommentCount,
    pa.LastVoteDate
FROM 
    FilteredUsers fu
JOIN 
    RankedPosts p ON fu.UserId = p.PostRank
JOIN 
    PostActivity pa ON p.PostId = pa.PostId
WHERE 
    p.PostRank <= 3
    AND (pa.CommentCount > 0 OR pa.LastVoteDate IS NOT NULL)
ORDER BY 
    fu.Reputation DESC, p.CreationDate DESC;
