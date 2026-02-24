WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        COALESCE(MAX(P.LastActivityDate), '1970-01-01') AS LastActivity,
        COALESCE(MAX(P.CreationDate), '1970-01-01') AS FirstPost
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        UB.TotalBadges,
        UB.GoldBadges,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.AverageScore,
        PS.TotalViews,
        PS.LastActivity,
        PS.FirstPost,
        (SELECT COUNT(*) 
         FROM Comments C 
         WHERE C.UserId = U.Id) AS TotalComments
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY COALESCE(TotalViews, 0) DESC, AverageScore DESC) AS Rank
    FROM CombinedStats
)
SELECT 
    DisplayName,
    TotalBadges, 
    GoldBadges, 
    QuestionCount,
    AnswerCount,
    AverageScore,
    TotalViews,
    LastActivity,
    FirstPost,
    Rank
FROM TopUsers
WHERE Rank <= 10
UNION ALL
SELECT 
    'Average Statistics' AS DisplayName,
    AVG(TotalBadges) AS TotalBadges,
    AVG(GoldBadges) AS GoldBadges,
    AVG(QuestionCount) AS QuestionCount,
    AVG(AnswerCount) AS AnswerCount,
    AVG(AverageScore) AS AverageScore,
    AVG(TotalViews) AS TotalViews,
    MAX(LastActivity) AS LastActivity,
    MIN(FirstPost) AS FirstPost,
    NULL AS Rank
FROM CombinedStats
WHERE TotalBadges IS NOT NULL;
