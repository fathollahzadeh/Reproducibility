WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        NTILE(5) OVER (ORDER BY U.Reputation DESC) AS ReputationBucket
    FROM 
        Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END) AS TotalScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
VoteSummary AS (
    SELECT 
        V.UserId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        PS.PostCount,
        PS.QuestionCount,
        PS.AnswerCount,
        COALESCE(VS.UpVotes, 0) AS UpVotes,
        COALESCE(VS.DownVotes, 0) AS DownVotes,
        UR.ReputationBucket
    FROM 
        UserReputation UR
    LEFT JOIN 
        PostStats PS ON UR.UserId = PS.OwnerUserId
    LEFT JOIN 
        VoteSummary VS ON UR.UserId = VS.UserId
    WHERE 
        UR.Reputation > 50
),
FilteredUsers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ReputationBucket ORDER BY UpVotes DESC) AS RankByVotes
    FROM 
        TopUsers 
    WHERE 
        UpVotes - DownVotes > 0  
)
SELECT
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    ReputationBucket,
    RankByVotes
FROM 
    FilteredUsers
WHERE 
    RankByVotes <= 5  
ORDER BY 
    ReputationBucket, RankByVotes;