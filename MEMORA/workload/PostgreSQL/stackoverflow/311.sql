WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        u.Reputation > 0 
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostCount,
        ur.TotalBounties,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.PostCount DESC) AS Ranking
    FROM 
        UserReputation ur
)
SELECT 
    tu.UserId,
    u.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalBounties,
    COALESCE(rp.Title, 'No Posts') AS RecentPostTitle,
    COALESCE(rp.CreationDate, NULL) AS RecentPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    Users u ON tu.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    tu.Ranking <= 10
ORDER BY 
    tu.Ranking;