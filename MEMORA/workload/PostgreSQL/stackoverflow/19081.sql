
SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS PostCount,
    SUM(v.BountyAmount) AS TotalBounty,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    u.DisplayName, u.Id
ORDER BY 
    PostCount DESC;
