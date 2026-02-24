
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    pt.Name AS PostType,
    ht.Name AS PostHistoryType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
LEFT JOIN 
    Badges b ON u.Id = b.UserId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name, ht.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
