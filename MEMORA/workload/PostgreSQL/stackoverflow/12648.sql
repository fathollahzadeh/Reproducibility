SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    COUNT(DISTINCT u.Id) AS UserCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.PostTypeId
ORDER BY 
    p.PostTypeId;