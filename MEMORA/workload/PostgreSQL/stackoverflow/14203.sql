SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2022-01-01'  
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;