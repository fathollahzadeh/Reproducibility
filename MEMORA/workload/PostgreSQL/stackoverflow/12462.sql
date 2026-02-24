SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT b.UserId) AS TotalUsersWithBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;