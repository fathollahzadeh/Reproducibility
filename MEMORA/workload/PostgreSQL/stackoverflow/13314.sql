
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.Score,
    COALESCE(u.Reputation, 0) AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
