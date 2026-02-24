
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty,
        AVG(COALESCE(P.Score, 0.0)) AS AvgScore,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        AvgScore,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserActivity
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalBounty,
    TU.AvgScore,
    TU.UpVotes,
    TU.DownVotes,
    ROW_NUMBER() OVER (PARTITION BY TU.ReputationRank ORDER BY TU.AvgScore DESC) AS ScoreRank
FROM 
    TopUsers TU
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, TU.UpVotes DESC;
