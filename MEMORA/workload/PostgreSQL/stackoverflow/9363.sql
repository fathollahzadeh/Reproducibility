
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
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
        BadgeCount,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
ActiveUsers AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Reputation,
        TU.PostCount,
        TU.AnswerCount,
        TU.QuestionCount,
        TU.BadgeCount,
        TU.ReputationRank,
        COALESCE(COM.TotalComments, 0) AS TotalComments
    FROM TopUsers TU
    LEFT JOIN (
        SELECT 
            C.UserId,
            COUNT(C.Id) AS TotalComments
        FROM Comments C
        GROUP BY C.UserId
    ) COM ON TU.UserId = COM.UserId
)
SELECT 
    AU.DisplayName,
    AU.Reputation,
    AU.PostCount,
    AU.AnswerCount,
    AU.QuestionCount,
    AU.BadgeCount,
    AU.ReputationRank,
    AU.TotalComments,
    (AU.AnswerCount::FLOAT / NULLIF(AU.QuestionCount, 0)) * 100 AS AnswerToQuestionRatio,
    (AU.BadgeCount::FLOAT / NULLIF(AU.PostCount, 0)) * 100 AS BadgeToPostRatio
FROM ActiveUsers AU
WHERE AU.ReputationRank <= 10
ORDER BY AU.Reputation DESC, AU.TotalComments DESC;
