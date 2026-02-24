SELECT u.DisplayName, 
       p.Title, 
       p.CreationDate, 
       p.Score, 
       COUNT(c.Id) as CommentCount
FROM Users u
JOIN Posts p ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON c.PostId = p.Id
WHERE p.PostTypeId = 1 
GROUP BY u.DisplayName, p.Title, p.CreationDate, p.Score
ORDER BY p.Score DESC
LIMIT 10;