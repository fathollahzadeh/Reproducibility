
SELECT p.Id,
       p.Title,
       u.DisplayName,
       p.CreationDate,
       p.Score
FROM Posts AS p
JOIN Users AS u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;