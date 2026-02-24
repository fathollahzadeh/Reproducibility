
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges,
        RANK() OVER (ORDER BY u2.Reputation DESC) AS UserRank
    FROM 
        UserBadgeCounts u
    JOIN 
        Users u2 ON u.UserId = u2.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    ORDER BY 
        p.CreationDate DESC
),
UserPostStats AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore
    FROM 
        RecentPosts rp
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.BadgeCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    ups.PostCount,
    ups.TotalViews,
    ups.TotalScore
FROM 
    TopUsers tu
LEFT JOIN 
    UserPostStats ups ON tu.UserId = ups.OwnerUserId
WHERE 
    tu.UserRank <= 10 
ORDER BY 
    tu.UserRank;
