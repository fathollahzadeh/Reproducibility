SELECT p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1  
ORDER BY p.CreationDate DESC
LIMIT 10;