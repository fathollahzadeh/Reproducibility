WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostType,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount,
        COUNT(c.Id) AS CommentsCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        pt.Name
)


, TotalCounts AS (
    SELECT 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT u.Id) AS TotalUsers
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
)


SELECT 
    pm.PostType,
    pm.AverageScore,
    pm.AverageViewCount,
    pm.CommentsCount,
    tc.TotalPosts,
    tc.TotalUsers
FROM 
    PostMetrics pm,
    TotalCounts tc
ORDER BY 
    pm.PostType;