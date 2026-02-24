WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AvgScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.CreationDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalAnswers, 
        TotalQuestions, 
        TotalScore,
        AvgScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostStats
    WHERE TotalPosts > 0
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalAnswers,
    TU.TotalQuestions,
    TU.TotalScore,
    TU.AvgScore,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    COALESCE(C.CommentCount, 0) AS TotalComments
FROM TopUsers TU
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(Id) AS BadgeCount 
    FROM Badges 
    GROUP BY UserId
) B ON TU.UserId = B.UserId
LEFT JOIN (
    SELECT 
        C.UserId, 
        COUNT(C.Id) AS CommentCount
    FROM Comments C
    JOIN Posts P ON C.PostId = P.Id
    WHERE P.OwnerUserId IS NOT NULL
    GROUP BY C.UserId
) C ON TU.UserId = C.UserId
WHERE TU.ScoreRank <= 10
ORDER BY TU.TotalScore DESC;