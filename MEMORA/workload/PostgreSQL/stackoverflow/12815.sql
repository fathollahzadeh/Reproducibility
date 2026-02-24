SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN u.Id IS NOT NULL THEN 1 ELSE 0 END) AS UserPostCount,
    AVG(u.Reputation) AS AverageUserReputation,
    SUM(c.CommentCount) AS TotalComments
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(Id) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON c.PostId = p.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;