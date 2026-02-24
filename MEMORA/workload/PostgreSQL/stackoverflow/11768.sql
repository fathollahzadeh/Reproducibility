SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    unnest(string_to_array(p.Tags, ',')) AS tagsl(tag) ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = trim(both ' ' from tagsl.tag)
WHERE 
    p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC
LIMIT 100;