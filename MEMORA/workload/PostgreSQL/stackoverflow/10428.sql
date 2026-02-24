SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
    SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
    AVG(COALESCE(EXTRACT(EPOCH FROM p.LastActivityDate - p.CreationDate), 0)) AS AvgTimeToActivity,
    COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(v.BountyAmount) AS TotalBountySpent
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;