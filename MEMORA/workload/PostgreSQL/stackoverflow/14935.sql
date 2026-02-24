
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.CreationDate < '2023-12-31'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId, u.DisplayName
)

SELECT 
    pt.Name AS PostType,
    COUNT(pm.PostId) AS TotalPosts,
    SUM(pm.ViewCount) AS TotalViews,
    AVG(pm.CommentCount) AS AverageComments
FROM 
    PostMetrics pm
JOIN 
    PostTypes pt ON pm.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalViews DESC;
