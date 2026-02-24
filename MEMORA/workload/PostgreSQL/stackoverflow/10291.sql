
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR' 
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.Reputation, u.DisplayName
ORDER BY 
    p.ViewCount DESC, p.Score DESC;
