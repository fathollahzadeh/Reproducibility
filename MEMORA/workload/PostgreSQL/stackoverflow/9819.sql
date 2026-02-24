WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    WHERE U.CreationDate >= cast('2024-10-01' as date) - INTERVAL '2 years'
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation,
        DENSE_RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        DENSE_RANK() OVER (ORDER BY TotalUpVotes DESC) AS RankByUpVotes
    FROM UserActivity
),
CombinedRankings AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        RankByReputation,
        RankByPosts,
        RankByUpVotes,
        LEAST(RankByReputation, RankByPosts, RankByUpVotes) AS OverallRank
    FROM TopUsers
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    OverallRank
FROM CombinedRankings
WHERE OverallRank <= 10
ORDER BY OverallRank;