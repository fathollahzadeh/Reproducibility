SELECT 
    u.DisplayName, 
    COUNT(p.Id) AS PostCount, 
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
