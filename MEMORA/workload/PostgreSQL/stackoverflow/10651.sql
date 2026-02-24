SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;