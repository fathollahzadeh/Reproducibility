
WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostType,
    TotalPosts,
    TotalComments,
    AvgViewCount,
    ROUND((TotalComments::decimal / NULLIF(TotalPosts, 0)), 2) AS AvgCommentsPerPost
FROM 
    PostMetrics
ORDER BY 
    TotalPosts DESC;
