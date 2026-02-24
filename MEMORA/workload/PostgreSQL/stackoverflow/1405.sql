
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(CASE WHEN b.Name IS NOT NULL THEN 1 END) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalBounties,
        ua.BadgeCount,
        ua.TotalPosts,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS UserRank
    FROM 
        UserActivity ua
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBounties,
    tu.BadgeCount,
    tu.TotalPosts,
    CASE WHEN tu.TotalPosts > 10 THEN 'High Contributor'
         WHEN tu.TotalPosts BETWEEN 5 AND 10 THEN 'Moderate Contributor'
         ELSE 'Low Contributor' END AS ContributorLevel,
    rp.Title,
    rp.Score,
    rp.ViewCount
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
