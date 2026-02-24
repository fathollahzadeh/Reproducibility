SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    AVG(u.Reputation) AS AverageReputation,
    AVG(COALESCE(c.CommentCount, 0)) AS AverageCommentCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount
     FROM Comments
     GROUP BY PostId) c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2020-01-01' 
    AND p.CreationDate < '2023-10-01';