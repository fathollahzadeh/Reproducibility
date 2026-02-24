SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END), 0) AS AcceptedAnswers,
    COALESCE(SUM(p.ViewCount) FILTER (WHERE p.ViewCount IS NOT NULL), 0) AS TotalViews,
    COALESCE(AVG(p.Score), 0) AS AverageScore,
    COALESCE(MAX(p.CreationDate), '1970-01-01') AS MostRecentPostDate,
    COALESCE(MIN(p.CreationDate), '1970-01-01') AS EarliestPostDate,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueOwners
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;