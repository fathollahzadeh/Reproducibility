WITH PostStatistics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)

SELECT 
    PostTypeName,
    TotalPosts,
    AverageViewCount
FROM 
    PostStatistics
ORDER BY 
    TotalPosts DESC;