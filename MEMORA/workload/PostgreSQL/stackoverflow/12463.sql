SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    SUM(u.Reputation) AS TotalUserReputation,
    AVG(p.Score) AS AveragePostScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;