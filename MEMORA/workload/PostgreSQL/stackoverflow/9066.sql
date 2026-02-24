SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    pt.Name AS PostTypeName,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(b.Date) AS LastBadgeDate,
    p.LastActivityDate AS LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND u.Reputation > 50
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, pt.Name, p.LastActivityDate
HAVING 
    COUNT(c.Id) > 5
ORDER BY 
    LastActivityDate DESC, UpVoteCount DESC;