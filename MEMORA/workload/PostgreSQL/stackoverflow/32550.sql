WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AveragePostScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AveragePostScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStats
    WHERE TotalPosts > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
UserScores AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.TotalPosts,
        t.TotalQuestions,
        t.TotalAnswers,
        t.AveragePostScore,
        COALESCE(ub.TotalBadges, 0) AS TotalBadges,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM TopUsers t
    LEFT JOIN UserBadges ub ON t.UserId = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AveragePostScore,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    CASE 
        WHEN TotalPosts > 100 THEN 'High Activity' 
        WHEN TotalPosts BETWEEN 50 AND 100 THEN 'Moderate Activity' 
        ELSE 'Low Activity' 
    END AS ActivityLevel
FROM UserScores
WHERE TotalPosts > 0
ORDER BY TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;