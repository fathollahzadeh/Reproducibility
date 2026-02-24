SELECT p.Title, COUNT(c.Id) AS CommentCount
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.PostTypeId = 1
GROUP BY p.Title
ORDER BY CommentCount DESC
LIMIT 10;
