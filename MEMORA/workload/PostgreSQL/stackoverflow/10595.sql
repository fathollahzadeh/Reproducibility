WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
AverageActivity AS (
    SELECT 
        AVG(TotalPosts) AS AvgPosts,
        AVG(TotalComments) AS AvgComments,
        AVG(TotalVotes) AS AvgVotes
    FROM UserActivity
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalVotes,
    AA.AvgPosts,
    AA.AvgComments,
    AA.AvgVotes
FROM UserActivity UA, AverageActivity AA
ORDER BY UA.TotalPosts DESC;