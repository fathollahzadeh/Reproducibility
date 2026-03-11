
SELECT p.Title,
       u.DisplayName AS OWNER,
       p.CreationDate,
       p.Score,
       p.ViewCount
FROM
  (SELECT Title,
          OwnerUserId,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC;