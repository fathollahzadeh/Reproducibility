SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
LEFT JOIN 
    Comments c ON u.Id = c.UserId AND c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
LEFT JOIN 
    Votes v ON u.Id = v.UserId AND v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;