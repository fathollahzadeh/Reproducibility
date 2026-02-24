WITH UserBadges AS (
    SELECT 
        U.Id as UserId, 
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS PostCount, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.QuestionCount, 0) AS TotalQuestions,
        COALESCE(PS.AnswerCount, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AvgScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
),
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC, TotalBadges DESC) AS Rank
    FROM CombinedStats
)
SELECT 
    UserId, 
    DisplayName, 
    TotalBadges, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalViews, 
    AvgScore, 
    Rank
FROM RankedUsers
WHERE Rank <= 10
ORDER BY Rank;
