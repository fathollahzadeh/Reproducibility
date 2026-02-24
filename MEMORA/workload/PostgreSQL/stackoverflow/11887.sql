SELECT 
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(v.Id) AS TotalVotes,
    COUNT(c.Id) AS TotalComments,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
LEFT JOIN 
    VoteTypes vt ON vt.Id = (SELECT VoteTypeId FROM Votes WHERE PostId = p.Id LIMIT 1)  
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;