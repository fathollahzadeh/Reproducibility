
SELECT 
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 MONTH'
GROUP BY 
    p.Id, p.Title, pt.Name, u.Reputation, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
