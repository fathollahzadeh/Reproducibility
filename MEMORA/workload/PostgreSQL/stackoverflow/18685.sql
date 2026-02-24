SELECT p.Title, p.CreationDate, u.DisplayName, p.Score
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  
ORDER BY p.Score DESC
LIMIT 10;