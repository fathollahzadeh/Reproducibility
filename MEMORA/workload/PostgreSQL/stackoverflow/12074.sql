
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score,
    u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;
