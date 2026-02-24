SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.Score) AS AvgScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.ClosedDate IS NULL AND 
    p.AcceptedAnswerId IS NOT NULL  
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;