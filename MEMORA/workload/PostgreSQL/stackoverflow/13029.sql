SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalQuestionsWithScore,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    COUNT(DISTINCT p.OwnerUserId) AS TotalUniquePostOwners,
    SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;