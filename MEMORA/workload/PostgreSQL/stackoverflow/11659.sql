SELECT 
    u.Id AS UserId,
    u.Reputation,
    u.CreationDate,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.Reputation, u.CreationDate
ORDER BY 
    PostCount DESC, Reputation DESC;