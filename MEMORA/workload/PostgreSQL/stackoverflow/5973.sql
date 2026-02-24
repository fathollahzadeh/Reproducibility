WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS TotalBadges,
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
        p.OwnerUserId, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
),
UserPostCounts AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId, 
    u.DisplayName,
    u.TotalBadges,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    up.PostCount,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViewCount
FROM 
    UserBadgeStats u
JOIN 
    UserPostCounts up ON u.UserId = up.OwnerUserId
LEFT JOIN 
    PopularPosts pp ON u.UserId = pp.OwnerUserId
WHERE 
    u.TotalBadges > 0
ORDER BY 
    u.TotalBadges DESC, 
    up.PostCount DESC;
