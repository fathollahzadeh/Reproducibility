WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.PostTypeId) AS UniquePostTypes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgPostDurationInSeconds
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
        UniquePostTypes,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        AvgPostDurationInSeconds,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    UniquePostTypes,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    AvgPostDurationInSeconds,
    ScoreRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10
ORDER BY 
    TotalScore DESC;