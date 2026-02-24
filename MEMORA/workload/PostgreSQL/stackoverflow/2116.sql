WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS HighestScorePost
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Most Recent Post'
        ELSE 'Other Post'
    END AS PostStatus
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    rp.HighestScorePost = 1
    AND EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = rp.PostId
        AND v.VoteTypeId = 2 
    )
ORDER BY 
    tu.Reputation DESC, rp.ViewCount DESC
LIMIT 10;