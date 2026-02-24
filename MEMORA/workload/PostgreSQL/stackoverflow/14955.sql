
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty,
    (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id) AS TotalVotes,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS OwnerBadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY 
    p.ViewCount DESC, p.Score DESC
LIMIT 100;
