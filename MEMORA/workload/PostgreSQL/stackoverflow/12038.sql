SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalPositiveScorePosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.AnswerCount) AS AverageAnswerCount,
    MAX(p.CreationDate) AS LatestPostDate,
    MIN(p.CreationDate) AS EarliestPostDate,
    COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;