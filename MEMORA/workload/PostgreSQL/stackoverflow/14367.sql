SELECT 
    pt.Name AS PostType,
    u.Reputation AS UserReputation,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.Score) AS AvgScore,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, u.Reputation
ORDER BY 
    PostCount DESC, UserReputation DESC;