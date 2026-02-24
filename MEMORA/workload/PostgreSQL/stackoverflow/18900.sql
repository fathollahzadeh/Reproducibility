
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(t.TagName, '') AS TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, STRING_AGG(TagName, ', ') AS TagName FROM Tags t JOIN Posts p ON t.ExcerptPostId = p.Id GROUP BY PostId) t ON p.Id = t.PostId
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount, c.CommentCount, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
