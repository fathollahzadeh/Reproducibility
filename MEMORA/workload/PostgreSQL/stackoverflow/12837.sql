SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(u.Reputation) AS TotalUserReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalPosts DESC;