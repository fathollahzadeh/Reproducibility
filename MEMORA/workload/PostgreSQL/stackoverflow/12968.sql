
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighlyViewedPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(EXTRACT(EPOCH FROM (COALESCE(p.LastActivityDate, CURRENT_TIMESTAMP) - p.CreationDate))) AS AveragePostAgeInSeconds,
    COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
