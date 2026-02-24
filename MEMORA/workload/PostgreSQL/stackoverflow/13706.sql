SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS QuestionCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalViews DESC;