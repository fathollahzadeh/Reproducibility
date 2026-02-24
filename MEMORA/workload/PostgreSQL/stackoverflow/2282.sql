
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AverageScore,
        TotalComments,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY AverageScore DESC) AS ScoreRank
    FROM UserPostStats
),
FilteredTopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AverageScore,
        TotalComments,
        PostRank,
        ScoreRank
    FROM TopUsers
    WHERE PostRank <= 10 OR ScoreRank <= 10
)
SELECT 
    f.DisplayName,
    COALESCE(b.Class, 0) AS BadgeClass,
    b.Name AS BadgeName,
    f.TotalPosts,
    f.TotalQuestions,
    f.TotalAnswers,
    f.AverageScore,
    f.TotalComments
FROM FilteredTopUsers f
LEFT JOIN Badges b ON f.UserId = b.UserId
WHERE b.Class IS NOT NULL
ORDER BY f.TotalPosts DESC, f.AverageScore DESC;
