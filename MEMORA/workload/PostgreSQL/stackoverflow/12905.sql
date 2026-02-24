SELECT 
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViewCount,
    AVG(p.Score) AS AverageScore
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;