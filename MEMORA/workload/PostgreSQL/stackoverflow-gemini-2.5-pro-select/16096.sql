
SELECT p.Title,
       u.DisplayName AS OWNER,
       p.CreationDate,
       p.Score,
       p.ViewCount
FROM Posts p
INNER JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1
ORDER BY p.CreationDate DESC
LIMIT 10;