SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(DISTINCT v.UserId) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE p.CreationDate >= '2023-01-01' 
GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY p.CreationDate DESC;