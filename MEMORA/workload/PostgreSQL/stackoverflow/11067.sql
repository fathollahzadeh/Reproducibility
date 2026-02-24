WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScorePerPost,
        AVG(p.ViewCount) AS AvgViewsPerPost
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
        PostCount,
        TotalScore,
        TotalViews,
        AvgScorePerPost,
        AvgViewsPerPost,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewsRank
    FROM 
        UserPostStats
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    AvgScorePerPost,
    AvgViewsPerPost,
    ScoreRank,
    ViewsRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR ViewsRank <= 10
ORDER BY 
    ScoreRank, ViewsRank;