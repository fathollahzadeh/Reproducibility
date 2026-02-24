WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM Posts P
    WHERE P.PostTypeId = 1 
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.PostCount,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalScore,
    TQ.QuestionId,
    TQ.Title,
    TQ.CreationDate,
    TQ.ViewCount,
    COALESCE(B.BadgeCount, 0) AS BulkBadgeCount
FROM UserStats US
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
) B ON US.UserId = B.UserId
LEFT JOIN TopQuestions TQ ON US.QuestionCount > 0 AND TQ.ScoreRank <= 10
WHERE 
    US.Reputation > 1000
AND 
    US.PostCount > 5
AND 
    NOT EXISTS (
        SELECT 1 
        FROM Votes V 
        WHERE V.UserId = US.UserId 
        AND V.VoteTypeId IN (3, 12) 
    )
ORDER BY US.TotalScore DESC, US.DisplayName ASC;