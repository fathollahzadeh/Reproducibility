SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    AVG(p.Score) AS AvgScore,
    MAX(p.Score) AS MaxScore
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    pt.Id;