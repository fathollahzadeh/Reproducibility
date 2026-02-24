
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikiCount,
        SUM(CASE WHEN V.VoteTypeId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        AVG(COALESCE(P.Score, 0)) AS AveragePostScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.Reputation, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        WikiCount,
        TagWikiCount,
        TotalVotes,
        AveragePostScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.WikiCount,
    TU.TagWikiCount,
    TU.TotalVotes,
    TU.AveragePostScore,
    RANK() OVER (ORDER BY TU.Reputation DESC) AS GlobalRank
FROM TopUsers TU
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC;
