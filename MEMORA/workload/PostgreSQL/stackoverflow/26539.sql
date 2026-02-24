WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        PopularPosts, 
        AvgScore, 
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        RANK() OVER (ORDER BY AvgScore DESC) AS RankByScore
    FROM 
        UserPostStats
),

ActiveBadges AS (
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
),

BenchmarkResults AS (
    SELECT 
        U.DisplayName,
        U.TotalPosts,
        U.TotalQuestions,
        U.TotalAnswers,
        U.PopularPosts,
        U.AvgScore,
        U.LastPostDate,
        AB.TotalBadges,
        AB.GoldBadges,
        AB.SilverBadges,
        AB.BronzeBadges,
        U.RankByPosts,
        U.RankByScore
    FROM 
        TopUsers U
    LEFT JOIN 
        ActiveBadges AB ON U.UserId = AB.UserId
)

SELECT 
    DisplayName, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers,
    PopularPosts, 
    AvgScore, 
    LastPostDate,
    TotalBadges, 
    GoldBadges, 
    SilverBadges, 
    BronzeBadges,
    RankByPosts, 
    RankByScore
FROM 
    BenchmarkResults
WHERE 
    TotalPosts > 10 
ORDER BY 
    RankByPosts, 
    RankByScore;
