
SELECT p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       p.ViewCount,
       p.Score
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.Id IN
    (SELECT Id
     FROM Posts
     WHERE PostTypeId = 1
     ORDER BY CreationDate DESC
     LIMIT 10)
ORDER BY p.CreationDate DESC;