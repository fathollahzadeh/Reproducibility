
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(SUM(p.Score), 0) AS TotalScore,
    COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COALESCE(SUM(b.Count), 0) AS TotalTags
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
         Id, COUNT(*) AS Count 
     FROM 
         Tags 
     GROUP BY 
         Id) b ON p.Tags LIKE '%' || b.Id || '%'
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
