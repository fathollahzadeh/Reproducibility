WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
),

TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVoteCount,
        DownVoteCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserReputation
)

SELECT 
    TU.UserId,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.UpVoteCount,
    TU.DownVoteCount,
    TU.ReputationRank
FROM TopUsers TU
WHERE TU.ReputationRank <= 10;