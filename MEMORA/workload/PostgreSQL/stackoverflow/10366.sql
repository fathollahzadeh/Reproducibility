
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
    COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS VoteCount,
    COALESCE(b.Id, 0) AS BadgeId,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, a.AcceptedAnswerId, b.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
