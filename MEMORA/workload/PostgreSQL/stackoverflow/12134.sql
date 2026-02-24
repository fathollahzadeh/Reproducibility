SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    COUNT(v.Id) AS TotalVotes,
    COUNT(DISTINCT u.Id) AS UniqueUsers
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;