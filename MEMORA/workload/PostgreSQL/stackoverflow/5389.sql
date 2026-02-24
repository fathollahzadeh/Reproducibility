WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS MostRecentPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ua.UserId,
    u.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.Wikis,
    ua.TotalViews,
    ua.TotalScore,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ua.MostRecentPost,
    ROW_NUMBER() OVER (ORDER BY ua.TotalScore DESC) AS Rank
FROM 
    UserActivity ua
JOIN 
    Users u ON ua.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.TotalScore DESC, ua.TotalPosts DESC;
