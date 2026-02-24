
WITH UserBadgeStats AS (
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
PostAggStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed,
        SUM(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS PostsDeleted
    FROM PostHistory PH
    GROUP BY PH.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PA.TotalPosts, 0) AS TotalPosts,
    COALESCE(PA.QuestionCount, 0) AS QuestionCount,
    COALESCE(PA.AnswerCount, 0) AS AnswerCount,
    COALESCE(PA.AvgScore, 0) AS AvgScore,
    COALESCE(PA.TotalViews, 0) AS TotalViews,
    COALESCE(PH.TotalEdits, 0) AS TotalEdits,
    COALESCE(PH.TitleEdits, 0) AS TitleEdits,
    COALESCE(PH.PostsClosed, 0) AS PostsClosed,
    COALESCE(PH.PostsDeleted, 0) AS PostsDeleted
FROM Users U
LEFT JOIN UserBadgeStats UB ON U.Id = UB.UserId
LEFT JOIN PostAggStats PA ON U.Id = PA.OwnerUserId
LEFT JOIN PostHistoryStats PH ON U.Id = PH.UserId
ORDER BY BadgeCount DESC, TotalPosts DESC, AvgScore DESC
LIMIT 100;
