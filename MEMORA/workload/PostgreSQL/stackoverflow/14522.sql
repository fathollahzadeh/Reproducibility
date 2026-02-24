
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'  
GROUP BY 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score, 
    u.DisplayName, 
    u.Reputation
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
