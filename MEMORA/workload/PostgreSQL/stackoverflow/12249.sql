SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(NULLIF(p.AnswerCount, 0), 0) AS AnswerCount,
    COALESCE(NULLIF(p.CommentCount, 0), 0) AS CommentCount,
    COALESCE(NULLIF(p.FavoriteCount, 0), 0) AS FavoriteCount,
    u.Reputation AS UserReputation,
    u.DisplayName AS OwnerDisplayName,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS VoteCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
    ph.CreationDate AS LastModifiedDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2023-01-01' 
ORDER BY 
    p.CreationDate DESC;