SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
    SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON c.PostId = p.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount 
     FROM Votes 
     GROUP BY PostId) v ON v.PostId = p.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;