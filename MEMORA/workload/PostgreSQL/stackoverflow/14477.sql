SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    COALESCE(SUM(u.Reputation), 0) AS TotalUserReputation,
    COUNT(ph.Id) AS PostHistoryCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;