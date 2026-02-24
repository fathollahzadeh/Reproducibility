
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.CommentCount) AS TotalComments,
    AVG(rp.Score) AS AvgScore,
    AVG(rp.ViewCount) AS AvgViewCount,
    MAX(ru.ReputationRank) AS MaxReputationRank
FROM 
    TopUsers ru
JOIN 
    RankedPosts rp ON ru.UserId = rp.OwnerPostRank
GROUP BY 
    ru.UserId, ru.DisplayName, ru.Reputation
HAVING 
    COUNT(DISTINCT rp.PostId) > 5 
ORDER BY 
    TotalComments DESC, AvgScore DESC;
