
SELECT p.Id AS PostId,
       p.Title,
       u.DisplayName AS OwnerName,
       p.CreationDate,
       p.Score,
       p.ViewCount
FROM
  (SELECT Id,
          OwnerUserId,
          CreationDate,
          Title,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC;