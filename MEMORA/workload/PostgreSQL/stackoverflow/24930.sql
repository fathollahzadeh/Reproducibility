
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        COUNT(c.Id) AS CommentCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate, ph.Comment
),
FinalResult AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COALESCE(RP.Title, 'No Posts') AS Title,
        COALESCE(RP.PostRank, 0) AS TopPostRank,
        COALESCE(CP.CommentCount, 0) AS ClosedPostCount,
        u.Reputation,
        u.QuestionCount,
        u.AnswerCount,
        u.BadgeCount
    FROM 
        UserStats u
    LEFT JOIN 
        RankedPosts RP ON u.UserId = RP.OwnerUserId AND RP.PostRank = 1
    LEFT JOIN 
        ClosedPosts CP ON u.UserId = CP.UserId 
)
SELECT 
    *,
    CASE 
        WHEN Reputation >= 1000 THEN 'Gold Contributor'
        WHEN Reputation >= 500 THEN 'Silver Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    FinalResult
WHERE 
    (TopPostRank IS NOT NULL OR ClosedPostCount > 0) 
ORDER BY 
    Reputation DESC, 
    TopPostRank ASC, 
    ClosedPostCount DESC;
