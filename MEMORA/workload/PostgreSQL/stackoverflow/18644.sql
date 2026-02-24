SELECT 
    u.DisplayName AS UserDisplayName, 
    COUNT(p.Id) AS PostCount, 
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 10;
