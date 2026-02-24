
SELECT 
    p.PostTypeId,
    AVG(p.Score) AS AvgPostScore,
    COUNT(c.Id) AS TotalComments,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    p.PostTypeId
ORDER BY 
    p.PostTypeId;
