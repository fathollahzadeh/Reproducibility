WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        COALESCE(uc.BadgeCount, 0) AS TotalBadges,
        uc.GoldBadges,
        uc.SilverBadges,
        uc.BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts uc ON u.Id = uc.UserId
    WHERE 
        Reputation > 1000
    ORDER BY 
        Reputation DESC
    LIMIT 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        TopUsers tu ON p.OwnerUserId = tu.Id
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBadges,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    TopUsers tu
INNER JOIN 
    RecentPosts rp ON tu.Id = rp.OwnerUserId
WHERE 
    rp.rn <= 3
ORDER BY 
    tu.Reputation DESC, rp.CreationDate DESC;
