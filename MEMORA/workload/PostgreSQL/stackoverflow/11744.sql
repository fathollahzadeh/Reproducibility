SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    COUNT(c.Id) AS CommentCount,
    COALESCE(AVG(v.TotalVotes), 0) AS AverageVotes
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    (SELECT 
         PostId, COUNT(Id) AS TotalVotes
     FROM 
         Votes
     GROUP BY 
         PostId) v ON v.PostId = p.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    PostTypeId;