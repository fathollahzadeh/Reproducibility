SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(u.Reputation) AS AvgUserReputation,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserNames
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;