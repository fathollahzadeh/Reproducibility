
SELECT p.Id AS PostId,
       p.Title,
       u.DisplayName AS OwnerName,
       p.CreationDate,
       p.Score,
       p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.Id IN
    (SELECT Id
     FROM Posts
     WHERE PostTypeId = 1
     ORDER BY CreationDate DESC
     LIMIT 10)
ORDER BY p.CreationDate DESC;