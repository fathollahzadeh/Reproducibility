SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalQuestions,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 
    AND u.Reputation > 100 
GROUP BY 
    u.DisplayName
ORDER BY 
    AverageScore DESC, AverageViewCount DESC;