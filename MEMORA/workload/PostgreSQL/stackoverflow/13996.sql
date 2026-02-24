
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.Score,
    p.ViewCount,
    p.Tags,
    p.AnswerCount,
    p.FavoriteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation, p.Score, p.ViewCount, p.Tags, p.AnswerCount, p.FavoriteCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
