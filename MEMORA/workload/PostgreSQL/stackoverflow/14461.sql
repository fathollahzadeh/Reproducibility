
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    b.Name AS BadgeName,
    b.Class AS BadgeClass,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    p.ViewCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate > '2020-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation, b.Name, b.Class, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
