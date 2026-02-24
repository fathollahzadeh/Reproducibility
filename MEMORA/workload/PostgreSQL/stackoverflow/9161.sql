WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT P2.Id) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Posts P2 ON U.Id = P2.OwnerUserId AND P2.PostTypeId = 2
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Rank,
        TotalPosts,
        TotalAnswers
    FROM UserRankings
    WHERE Rank <= 10
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
UserPostInteraction AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        P.Id AS PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.CommentCount,
        PS.VoteCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN PostStatistics PS ON P.Id = PS.PostId
)
SELECT 
    TU.DisplayName AS TopUser,
    COUNT(DISTINCT UPI.PostId) AS UserPostCount,
    SUM(UPI.Score) AS TotalScore,
    AVG(UPI.ViewCount) AS AverageViews,
    AVG(UPI.CommentCount) AS AverageComments,
    AVG(UPI.VoteCount) AS AverageVotes
FROM TopUsers TU
JOIN UserPostInteraction UPI ON TU.UserId = UPI.UserId
GROUP BY TU.DisplayName
ORDER BY TotalScore DESC;