SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AverageScore, 
    MAX(p.LastEditDate) AS MostRecentEditDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;