WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount,
        AnswerCount,
        QuestionCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
)
SELECT 
    U.DisplayName, 
    U.Reputation, 
    U.PostCount, 
    U.AnswerCount, 
    U.QuestionCount,
    (SELECT COUNT(*) FROM TopUsers) AS TotalUsers,
    ROUND((CAST(U.Reputation AS DECIMAL) / NULLIF((SELECT MAX(Reputation) FROM TopUsers), 0)) * 100, 2) AS ReputationPercentage
FROM TopUsers U
WHERE U.Rank <= 10
ORDER BY U.Reputation DESC;
