
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
