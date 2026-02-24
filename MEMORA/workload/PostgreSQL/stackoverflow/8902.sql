
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
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
        TotalBounties,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStatistics
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.AnswerCount,
    T.QuestionCount,
    T.TotalBounties,
    T.UpVotes,
    T.DownVotes
FROM TopUsers T
WHERE T.ReputationRank <= 10
ORDER BY T.Reputation DESC;
