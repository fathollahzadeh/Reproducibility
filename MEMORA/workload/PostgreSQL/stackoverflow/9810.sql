
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        EXTRACT(YEAR FROM P.CreationDate) AS PostYear,
        COUNT(C.*) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.CreationDate, P.Score
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.NetVotes,
        US.PostCount,
        US.QuestionCount,
        US.AnswerCount,
        RANK() OVER (ORDER BY US.Reputation DESC) AS ReputationRank
    FROM 
        UserScores US
    WHERE 
        US.PostCount > 0
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.NetVotes,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    COUNT(DISTINCT PS.PostId) AS ContributionPosts,
    SUM(PS.Score) AS TotalScore,
    SUM(PS.CommentCount) AS TotalComments,
    STRING_AGG(DISTINCT CAST(EXTRACT(YEAR FROM PS.CreationDate) AS TEXT), ', ') AS ActiveYears
FROM 
    TopUsers TU
JOIN 
    PostStatistics PS ON TU.UserId = PS.OwnerUserId
WHERE 
    TU.ReputationRank <= 10
GROUP BY 
    TU.UserId, TU.DisplayName, TU.Reputation, TU.NetVotes, TU.PostCount, TU.QuestionCount, TU.AnswerCount
ORDER BY 
    TU.Reputation DESC;
