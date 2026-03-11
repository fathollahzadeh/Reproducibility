
SELECT p.Id,
       p.Title,
       u.DisplayName,
       p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.Id IN
    (SELECT Id
     FROM Posts
     WHERE PostTypeId = 1
     ORDER BY CreationDate DESC
     LIMIT 10)
ORDER BY p.CreationDate DESC;