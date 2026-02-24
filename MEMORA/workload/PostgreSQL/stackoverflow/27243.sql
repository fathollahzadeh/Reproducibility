
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
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
        COUNT(P.Id) AS PostCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.QuestionsCount, 0) AS TotalQuestions,
        COALESCE(PS.AnswersCount, 0) AS TotalAnswers,
        COALESCE(PS.AverageScore, 0) AS AvgPostScore,
        COALESCE(PS.TotalViews, 0) AS TotalPostViews,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostStatistics PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.AvgPostScore,
    U.TotalPostViews,
    RANK() OVER (ORDER BY U.BadgeCount DESC, U.TotalPostViews DESC) AS Rank
FROM 
    UserPerformance U
WHERE 
    U.BadgeCount > 0 OR U.TotalPosts > 0
ORDER BY 
    Rank, U.DisplayName;
