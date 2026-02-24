
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalBounty,
        us.PostCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        RANK() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM 
        UserStatistics us
)
SELECT 
    ru.PostRank,
    ru.Title,
    ru.Score,
    ru.ViewCount,
    tu.DisplayName AS UserName,
    tu.Reputation,
    tu.TotalBounty,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges
FROM 
    RankedPosts ru
JOIN 
    TopUsers tu ON ru.Id = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId ORDER BY p.Score DESC LIMIT 1)
WHERE 
    ru.PostRank = 1
ORDER BY 
    ru.Score DESC, tu.Reputation DESC
LIMIT 10;
