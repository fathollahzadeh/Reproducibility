
SELECT 
    p.Id AS PostId,
    p.Title,
    p.PostTypeId,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) AS RevisionCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
GROUP BY 
    p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score, 
    p.AnswerCount, p.CommentCount, p.FavoriteCount, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;
