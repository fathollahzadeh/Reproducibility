
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.CreationDate < '2024-01-01' AND 
        p.Score > 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts pp WHERE pp.OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    u.Reputation AS UserReputation,
    COALESCE(rc.CommentCount, 0) AS TotalComments,
    rc.LastCommentDate,
    CASE 
        WHEN pp.PostRank = 1 THEN 'Latest'
        ELSE 'Earlier'
    END AS PostStatus,
    CASE 
        WHEN u.GoldBadges > 0 THEN 'Gold'
        ELSE 'Regular'
    END AS UserType
FROM 
    RankedPosts pp
JOIN 
    UserReputation u ON pp.OwnerUserId = u.UserId
LEFT JOIN 
    RecentComments rc ON pp.PostId = rc.PostId
WHERE 
    pp.Score > (SELECT AVG(Score) FROM Posts WHERE Score > 0) 
    AND pp.PostId IN (SELECT DISTINCT PostId FROM Votes v WHERE v.VoteTypeId IN (2, 3))
ORDER BY 
    pp.CreationDate DESC
LIMIT 100;
