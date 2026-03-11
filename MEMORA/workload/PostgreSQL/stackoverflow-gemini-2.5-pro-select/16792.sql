
SELECT u.DisplayName,
       p.Title,
       p.CreationDate
FROM
  (SELECT OwnerUserId,
          Title,
          CreationDate
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC;