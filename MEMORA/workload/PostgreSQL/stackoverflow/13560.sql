
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (
        SELECT COUNT(DISTINCT ph.UserId) 
        FROM PostHistory ph 
        WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11) 
    ) AS CloseReopenCount,
    (
        SELECT COUNT(DISTINCT b.Id)
        FROM Badges b
        WHERE b.UserId = p.OwnerUserId
    ) AS OwnerBadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
