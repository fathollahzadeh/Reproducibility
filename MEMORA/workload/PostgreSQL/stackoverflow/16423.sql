SELECT 
    p.Id as PostId,
    p.Title,
    u.DisplayName as OwnerName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
WHERE 
    p.PostTypeId = 1
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
