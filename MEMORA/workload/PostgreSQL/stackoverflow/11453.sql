SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.AnswerCount) AS AvgAnswerCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    pt.Name
ORDER BY 
    AvgScore DESC;