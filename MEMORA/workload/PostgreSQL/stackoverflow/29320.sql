WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalWikiPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalWikiPosts,
        PositiveScorePosts,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStatistics
    WHERE 
        TotalPosts > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserStatistics AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.TotalPosts,
        tu.TotalQuestions,
        tu.TotalAnswers,
        tu.TotalWikiPosts,
        tu.PositiveScorePosts,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        TopUsers tu
    LEFT JOIN 
        UserBadges ub ON tu.UserId = ub.UserId
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalWikiPosts,
    us.PositiveScorePosts,
    COALESCE(us.TotalBadges, 0) AS TotalBadges,
    COALESCE(us.GoldBadges, 0) AS GoldBadges,
    COALESCE(us.SilverBadges, 0) AS SilverBadges,
    COALESCE(us.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserStatistics us
WHERE 
    us.TotalPosts > 10
ORDER BY 
    us.TotalPosts DESC
LIMIT 10;
