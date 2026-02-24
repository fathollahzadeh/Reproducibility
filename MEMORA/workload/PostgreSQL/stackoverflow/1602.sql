WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.TotalBounties,
        RANK() OVER (ORDER BY ur.Reputation + ur.TotalBounties DESC) AS UserRank
    FROM 
        UserReputation ur
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    ur.TotalBounties,
    tp.UserRank
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    TopUsers tp ON ur.UserId = tp.UserId
WHERE 
    p.rn = 1
    AND p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
    OR ur.Reputation > 5000
ORDER BY 
    tp.UserRank, p.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;