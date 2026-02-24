
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS QuestionsWithScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score END) AS AverageScore,
    AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount END) AS AverageViews,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
