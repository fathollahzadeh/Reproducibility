SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalVotes,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    SUM(u.Reputation) AS TotalUserReputation,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;