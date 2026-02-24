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
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswerCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM UserBadges UB
    LEFT JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
),
RankedStats AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalScore DESC, QuestionCount DESC, AnswerCount DESC) AS OverallRank
    FROM CombinedStats
)
SELECT 
    UserId,
    DisplayName,
    TotalScore,
    QuestionCount,
    AnswerCount,
    AcceptedAnswerCount,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    OverallRank
FROM RankedStats
WHERE OverallRank <= 100
ORDER BY OverallRank;
