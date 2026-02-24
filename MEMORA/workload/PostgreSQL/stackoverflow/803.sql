WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 10
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(*) AS PostCount
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id, u.Reputation
), TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        PERCENT_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
)
SELECT 
    u.DisplayName,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    tu.ReputationRank
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON r.PostId = c.PostId
JOIN 
    TopUsers tu ON r.OwnerUserId = tu.UserId
WHERE 
    tu.ReputationRank < 0.1
ORDER BY 
    r.CreationDate DESC
LIMIT 50;
