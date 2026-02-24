WITH PostStatistics AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY
        pt.Name
)

SELECT 
    *,
    RANK() OVER (ORDER BY AverageScore DESC) AS ScoreRank
FROM 
    PostStatistics
ORDER BY 
    TotalPosts DESC;