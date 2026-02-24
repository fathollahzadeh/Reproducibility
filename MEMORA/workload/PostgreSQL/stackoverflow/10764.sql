
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    p.CreationDate,
    u.Id AS UserId,
    u.DisplayName AS Author,
    u.Reputation,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2020-01-01' 
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, 
    p.FavoriteCount, p.CreationDate, u.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;
