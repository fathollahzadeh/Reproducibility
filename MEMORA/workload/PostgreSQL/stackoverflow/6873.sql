WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        AVG(P.ViewCount) AS AverageViewsPerPost,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotedPosts,
        AverageViewsPerPost,
        Rank
    FROM UserPostStats
    WHERE Rank <= 10
),
LatestPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalUpvotedPosts,
    TU.AverageViewsPerPost,
    LP.PostId,
    LP.Title,
    LP.CreationDate,
    LP.ViewCount,
    LP.Score
FROM TopUsers TU
LEFT JOIN LatestPosts LP ON LP.OwnerDisplayName = TU.DisplayName
ORDER BY TU.Rank, LP.CreationDate DESC;