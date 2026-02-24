
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
UserRanked AS (
    SELECT 
        us.UserId,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalViews,
        us.TotalScore,
        us.AvgScore,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS PostsRank
    FROM 
        UserStatistics us
)
SELECT 
    ur.UserId,
    ur.TotalPosts,
    ur.TotalQuestions,
    ur.TotalAnswers,
    ur.TotalViews,
    ur.TotalScore,
    ur.AvgScore,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ur.ScoreRank,
    ur.PostsRank,
    ROW_NUMBER() OVER (ORDER BY ur.TotalViews DESC) AS ViewsRank
FROM 
    UserRanked ur
WHERE 
    ur.TotalPosts > 10
ORDER BY 
    ur.TotalScore DESC, 
    ur.TotalPosts DESC;
