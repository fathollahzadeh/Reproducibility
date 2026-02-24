WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
), 
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalViews,
    U.AverageScore,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    RANK() OVER (ORDER BY U.BadgeCount DESC) AS BadgeRank,
    RANK() OVER (ORDER BY U.TotalPosts DESC) AS PostRank
FROM 
    UserPerformance U
WHERE 
    U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC, 
    U.BadgeCount DESC, 
    U.TotalPosts DESC
LIMIT 10;
