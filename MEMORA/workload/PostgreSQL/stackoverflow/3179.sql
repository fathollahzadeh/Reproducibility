WITH UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.TotalViews,
        RANK() OVER (ORDER BY COALESCE(ub.GoldBadges, 0) DESC, ps.TotalViews DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ru.DisplayName,
    ru.UserRank,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ru.TotalPosts,
    ru.Questions,
    ru.Answers,
    ru.TotalViews
FROM 
    RankedUsers ru
WHERE 
    ru.UserRank <= 10
ORDER BY 
    ru.UserRank;
