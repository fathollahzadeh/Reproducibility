
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(t.TagName, 'No Tags') AS TagName
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT 
         t.Id, 
         t.TagName, 
         pt.PostId
     FROM 
         Tags t 
     JOIN 
         (SELECT 
             p.Id AS PostId, 
             unnest(string_to_array(p.Tags, '>')) AS Tag 
         FROM 
             Posts p) AS pt ON t.TagName = pt.Tag) t ON p.Id = t.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
