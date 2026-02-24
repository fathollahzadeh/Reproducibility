WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(p.Score) AS AverageScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.AnswerCount) AS AverageAnswersPerQuestion
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        AcceptedAnswers,
        AverageScore,
        TotalViews,
        AverageAnswersPerQuestion,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    AcceptedAnswers,
    AverageScore,
    TotalViews,
    AverageAnswersPerQuestion
FROM 
    TopUsers
WHERE 
    PostRank <= 10
ORDER BY 
    PostRank;