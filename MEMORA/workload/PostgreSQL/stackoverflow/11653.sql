SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE 
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, p.Title, p.CreationDate, p.Score, p.ViewCount, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
