WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeStatistics AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalViews,
    US.TotalScore,
    US.AvgScore,
    COALESCE(BS.TotalBadges, 0) AS TotalBadges,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserStatistics US
LEFT JOIN 
    BadgeStatistics BS ON US.UserId = BS.UserId
ORDER BY 
    US.TotalScore DESC, US.TotalPosts DESC;