
WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    TotalViews,
    TotalScore,
    AverageViews,
    AverageScore,
    ROUND(TotalViews / NULLIF(TotalPosts, 0), 2) AS ViewsPerPost,
    ROUND(TotalScore / NULLIF(TotalPosts, 0), 2) AS ScorePerPost
FROM 
    PostMetrics
ORDER BY 
    TotalPosts DESC;
