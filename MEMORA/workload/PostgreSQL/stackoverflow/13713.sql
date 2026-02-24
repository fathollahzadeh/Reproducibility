SELECT 
    p.PostTypeId, 
    pt.Name AS PostType,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.PostTypeId, pt.Name, u.Reputation
ORDER BY 
    p.PostTypeId, u.Reputation DESC;