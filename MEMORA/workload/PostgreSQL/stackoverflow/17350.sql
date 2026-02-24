SELECT u.DisplayName, p.Title, p.Score, COUNT(c.Id) AS CommentCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.PostTypeId = 1 
GROUP BY u.DisplayName, p.Title, p.Score
ORDER BY p.Score DESC
LIMIT 10;