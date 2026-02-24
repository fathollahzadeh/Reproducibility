
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.Score > 0 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    u.DisplayName,
    u.ReputationLevel,
    COALESCE(s.CommentCount, 0) AS CommentCount,
    COALESCE(s.TotalBounty, 0) AS TotalBounty,
    r.Score AS PostScore,
    r.ViewCount,
    CASE 
        WHEN r.rn = 1 THEN 'Latest Post'
        ELSE NULL
    END AS Tag
FROM 
    RankedPosts r
JOIN 
    UserReputation u ON r.OwnerUserId = u.UserId
LEFT JOIN 
    PostStatistics s ON r.PostId = s.PostId
WHERE 
    u.ReputationLevel IN ('High', 'Medium')
ORDER BY 
    r.CreationDate DESC
LIMIT 50;
