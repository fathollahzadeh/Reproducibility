
WITH UserBadges AS (
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
PopularPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserPostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount, 
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ub.UserId, 
    ub.DisplayName, 
    ub.BadgeCount, 
    ub.GoldBadges, 
    ub.SilverBadges, 
    ub.BronzeBadges,
    ups.PostCount, 
    ups.TotalViews, 
    ups.TotalScore,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViewCount
FROM 
    UserBadges ub
LEFT JOIN 
    UserPostStats ups ON ub.UserId = ups.OwnerUserId
LEFT JOIN 
    PopularPosts pp ON ub.UserId = pp.OwnerUserId AND pp.PopularityRank = 1
ORDER BY 
    ub.BadgeCount DESC, 
    ups.TotalViews DESC;
