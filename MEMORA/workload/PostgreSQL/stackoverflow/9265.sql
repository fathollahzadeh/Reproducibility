
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        PositivePosts, 
        AverageScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStats
)
SELECT 
    t1.DisplayName, 
    t1.TotalPosts, 
    t1.TotalQuestions, 
    t1.TotalAnswers, 
    t1.PositivePosts, 
    t1.AverageScore,
    t2.DisplayName AS TopAnswerer,
    t2.TotalAnswers AS TopAnswersCount
FROM TopUsers t1
LEFT JOIN TopUsers t2 ON t1.TotalAnswers < t2.TotalAnswers
WHERE t1.PostRank <= 10
ORDER BY t1.TotalPosts DESC;
