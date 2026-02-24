SELECT u.DisplayName, p.Title, p.CreationDate, COUNT(c.Id) AS CommentCount
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.PostTypeId = 1
GROUP BY u.DisplayName, p.Title, p.CreationDate
ORDER BY CommentCount DESC
LIMIT 10;
