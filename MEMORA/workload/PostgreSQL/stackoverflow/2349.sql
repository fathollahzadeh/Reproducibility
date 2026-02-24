WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        RANK() OVER (ORDER BY COALESCE(ps.TotalPosts, 0) DESC, COALESCE(ps.TotalViews, 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats bs ON u.Id = bs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 100
)
SELECT 
    u.DisplayName,
    u.UserRank,
    CONCAT(u.GoldBadges, ' Gold, ', u.SilverBadges, ' Silver, ', u.BronzeBadges, ' Bronze') AS BadgeCount,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.TotalViews
FROM 
    TopUsers u
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank;
