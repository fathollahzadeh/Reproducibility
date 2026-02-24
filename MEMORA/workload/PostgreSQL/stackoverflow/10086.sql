SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalViews DESC, TotalPosts DESC;