SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(c.CommentCount) AS TotalComments,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c 
    ON c.PostId = p.Id
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;