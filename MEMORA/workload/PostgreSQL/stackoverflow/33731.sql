
WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id, 
        U.Reputation, 
        COALESCE(BadgeCounts.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) AS BadgeCounts ON U.Id = BadgeCounts.UserId
), 
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COUNT(CM.Id) AS CommentCount
    FROM Users U
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN Comments CM ON U.Id = CM.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, PS.QuestionCount, PS.AnswerCount, PS.TotalScore
),
FinalStats AS (
    SELECT 
        UR.Id AS UserId,
        UR.Reputation,
        UR.BadgeCount,
        UA.DisplayName,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.TotalScore,
        UA.CommentCount,
        ROW_NUMBER() OVER (ORDER BY UA.TotalScore DESC) AS Rank,
        CASE 
            WHEN UR.Reputation >= 1000 THEN 'High'
            WHEN UR.Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM UserReputation UR
    JOIN UserActivity UA ON UR.Id = UA.Id
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    CommentCount,
    Rank,
    ReputationCategory
FROM FinalStats
WHERE BadgeCount > 0 
ORDER BY Rank, DisplayName;
