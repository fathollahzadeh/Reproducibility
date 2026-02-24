
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation,
    u.CreationDate AS AuthorCreationDate,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(COUNT(v.Id), 0) AS VoteCount,
    COALESCE(MAX(b.Name), 'No Badge') AS BadgeName
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
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation, u.CreationDate
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
