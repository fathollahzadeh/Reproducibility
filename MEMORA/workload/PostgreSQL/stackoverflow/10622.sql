SELECT 
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(u.Reputation) OVER () AS AvgReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;