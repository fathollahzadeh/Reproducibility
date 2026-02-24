WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(COALESCE(U.UpVotes, 0) - COALESCE(U.DownVotes, 0)) AS NetVotes
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(UB.NetVotes, 0) AS NetVotes,
        CASE 
            WHEN COALESCE(PS.LastPostDate, '1900-01-01') > '2022-01-01' THEN 'Active'
            ELSE 'Inactive'
        END AS ActivityStatus
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViews,
    NetVotes,
    ActivityStatus
FROM CombinedStats
WHERE (QuestionCount + AnswerCount) > 0
ORDER BY TotalScore DESC, GoldBadges DESC, SilverBadges DESC
LIMIT 10;