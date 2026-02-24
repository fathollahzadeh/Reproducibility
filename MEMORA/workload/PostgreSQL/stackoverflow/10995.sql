SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    AVG(p.Score) AS AverageScore,
    AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate)) / 60) AS AverageResponseTimeInMinutes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
GROUP BY 
    pt.Name
ORDER BY 
    CommentCount DESC, AverageScore DESC
LIMIT 10;