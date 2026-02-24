WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeCount,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.GoldCount,
        UB.SilverCount,
        UB.BronzeCount,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.TotalViews,
        PS.AverageScore
    FROM 
        Users U
    JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    WHERE 
        U.Reputation > 1000
    ORDER BY 
        PS.TotalPosts DESC, 
        U.Reputation DESC
    LIMIT 10
)
SELECT 
    AU.DisplayName,
    AU.TotalPosts,
    AU.TotalQuestions,
    AU.TotalAnswers,
    AU.TotalViews,
    AU.AverageScore,
    AU.GoldCount,
    AU.SilverCount,
    AU.BronzeCount
FROM 
    ActiveUsers AU
ORDER BY 
    AU.TotalPosts DESC;
