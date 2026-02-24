SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation

FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON c.PostId = p.Id
LEFT JOIN Votes v ON v.PostId = p.Id
LEFT JOIN Badges b ON b.UserId = u.Id

WHERE p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score, 
    u.DisplayName, 
    u.Reputation

ORDER BY p.Score DESC, p.ViewCount DESC;