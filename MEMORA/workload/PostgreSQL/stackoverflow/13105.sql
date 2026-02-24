SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;