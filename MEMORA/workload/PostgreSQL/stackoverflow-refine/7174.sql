
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswers
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AvgScore, 0) AS AverageScore,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        (COALESCE(UB.BadgeCount, 0) + COALESCE(PS.PostCount, 0)) AS CombinedScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    TotalPosts,
    TotalViews,
    AverageScore,
    TotalAnswers,
    CombinedScore
FROM 
    CombinedStats
ORDER BY 
    CombinedScore DESC,
    TotalViews DESC,
    AverageScore DESC
LIMIT 10;
