WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        B.Class,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes, B.Class
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
BadgesByUser AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
),
UserPerformance AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.BadgeCount,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.AvgScore,
        BB.BadgeNames,
        CASE 
            WHEN PS.QuestionCount > 10 THEN 'Active'
            WHEN PS.QuestionCount <= 10 AND PS.AnswerCount >= 5 THEN 'Moderate'
            ELSE 'Low'
        END AS ActivityLevel
    FROM UserScores US
    LEFT JOIN PostStatistics PS ON US.UserId = PS.OwnerUserId
    LEFT JOIN BadgesByUser BB ON US.UserId = BB.UserId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.Reputation,
    COALESCE(UP.BadgeCount, 0) AS BadgeCount,
    COALESCE(UP.QuestionCount, 0) AS QuestionCount,
    COALESCE(UP.AnswerCount, 0) AS AnswerCount,
    COALESCE(UP.AvgScore, 0) AS AvgScore,
    UP.BadgeNames,
    UP.ActivityLevel,
    CASE 
        WHEN UP.Reputation IS NULL THEN 'Reputation not available'
        ELSE CASE 
            WHEN UP.Reputation > 1000 THEN 'High Reputation'
            WHEN UP.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END
    END AS ReputationCategory
FROM UserPerformance UP
ORDER BY UP.Reputation DESC NULLS LAST, UP.QuestionCount DESC, UP.AnswerCount DESC;
