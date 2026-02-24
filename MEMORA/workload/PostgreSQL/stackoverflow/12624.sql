
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    AVG(v.BountyAmount) AS AvgBountyAmount,
    MAX(b.Date) AS LastBadgeDate,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.PostTypeId = 1 
    AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastActivityDate, p.ViewCount, b.Date
ORDER BY 
    p.ViewCount DESC;
