
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    COUNT(c.Id) AS CommentCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    ARRAY_AGG(DISTINCT bh.UserDisplayName) AS Editors
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag)
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
    p.CommentCount, p.FavoriteCount, u.Id, u.DisplayName, 
    u.Reputation, u.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 
    100;
