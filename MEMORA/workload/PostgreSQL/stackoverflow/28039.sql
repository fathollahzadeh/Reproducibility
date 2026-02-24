WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        TotalAcceptedAnswers,
        AverageScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserPostStatistics
),
TopRanked AS (
    SELECT 
        *,
        CASE 
            WHEN ScoreRank <= 10 THEN 'Top 10 by Score'
            WHEN ViewRank <= 10 THEN 'Top 10 by Views'
            ELSE 'Other'
        END AS RankCategory
    FROM 
        TopUsers
)
SELECT 
    RankCategory,
    COUNT(UserId) AS UserCount,
    SUM(TotalPosts) AS CombinedPosts,
    SUM(TotalQuestions) AS CombinedQuestions,
    SUM(TotalAnswers) AS CombinedAnswers,
    SUM(TotalScore) AS CombinedScore,
    SUM(TotalViews) AS CombinedViews,
    AVG(AverageScore) AS AverageScore
FROM 
    TopRanked
GROUP BY 
    RankCategory
ORDER BY 
    UserCount DESC;
