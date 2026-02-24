
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    p.PostTypeId,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    u.DisplayName AS OwnerDisplayName,
    t.TagName AS TagName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT p2.Id, unnest(string_to_array(p2.Tags, ',')) AS TagName 
     FROM Posts p2) t ON p.Id = t.Id
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score, 
    u.DisplayName, t.TagName
ORDER BY 
    p.ViewCount DESC
LIMIT 100;
