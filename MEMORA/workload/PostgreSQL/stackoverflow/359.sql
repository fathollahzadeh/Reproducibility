
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation + ur.TotalBounty DESC) AS UserRank
    FROM 
        UserReputation ur
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tu.UserId AS TopUserId,
    tu.Reputation AS UserReputation,
    tu.TotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.Rank = 1 AND rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId)
WHERE 
    rp.Score > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
