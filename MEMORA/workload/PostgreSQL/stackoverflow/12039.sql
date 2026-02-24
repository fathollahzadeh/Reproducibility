SELECT 
    pt.Name AS PostType,
    DATE_TRUNC('month', p.CreationDate) AS CreationMonth,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name, DATE_TRUNC('month', p.CreationDate)
ORDER BY 
    pt.Name, CreationMonth;