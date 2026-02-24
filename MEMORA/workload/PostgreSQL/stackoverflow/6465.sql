
SELECT 
    p.Title AS PostTitle,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    CASE WHEN ph.PostId IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(p.LastActivityDate) AS LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
LEFT JOIN 
    unnest(string_to_array(p.Tags, '><')) AS tag_name ON true
LEFT JOIN 
    Tags t ON t.TagName = tag_name
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, u.DisplayName, p.CreationDate, ph.PostId
ORDER BY 
    LastActivityDate DESC
LIMIT 
    50;
