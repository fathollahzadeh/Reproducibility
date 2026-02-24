
WITH UserScoreStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(COALESCE(VoteCount, 0)) AS TotalVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount 
         FROM Votes 
         GROUP BY PostId) AS VCounts ON P.Id = VCounts.PostId
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
        TotalVotes, 
        Upvotes, 
        Downvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM 
        UserScoreStats
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    PostCount, 
    TotalVotes, 
    Upvotes, 
    Downvotes, 
    ReputationRank, 
    VoteRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10 OR VoteRank <= 10
ORDER BY 
    Reputation DESC, 
    VoteRank;
