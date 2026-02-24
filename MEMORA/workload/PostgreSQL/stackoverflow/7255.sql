
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(COALESCE(P.Score, 0)) AS AveragePostScore,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        AveragePostScore,
        UserRank
    FROM UserStats
    WHERE UserRank <= 10
)
SELECT 
    T.DisplayName,
    T.TotalPosts,
    T.TotalComments,
    T.TotalUpvotes,
    T.TotalDownvotes,
    T.AveragePostScore,
    RANK() OVER (ORDER BY T.AveragePostScore DESC) AS ScoreRank
FROM TopUsers T
ORDER BY ScoreRank;
