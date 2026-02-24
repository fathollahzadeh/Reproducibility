WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        QuestionCount,
        AnswerCount,
        PositiveVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
)
SELECT 
    TU.DisplayName,
    TU.Reputation, 
    TU.QuestionCount,
    TU.AnswerCount,
    TU.PositiveVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = TU.UserId AND V.VoteTypeId = 2) AS UpVotesGiven,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = TU.UserId AND V.VoteTypeId = 3) AS DownVotesGiven,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = TU.UserId) AS BadgeCount
FROM 
    TopUsers TU
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC;