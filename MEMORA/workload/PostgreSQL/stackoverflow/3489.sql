WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*)
                  FROM Comments c
                  WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*)
         FROM Posts p
         WHERE p.OwnerUserId = u.Id) AS TotalPosts
    FROM 
        Users u
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
),
TopUsers AS (
    SELECT
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalPosts,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    tu.UserId,
    tu.DisplayName AS UserName,
    tu.Reputation AS UserReputation
FROM 
    RecentPosts rp
JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    TopUsers tu ON p.OwnerUserId = tu.UserId
WHERE 
    rp.rn = 1 
    AND (rp.CommentCount > 5 OR rp.Score > 10)
ORDER BY 
    rp.ViewCount DESC
LIMIT 50;