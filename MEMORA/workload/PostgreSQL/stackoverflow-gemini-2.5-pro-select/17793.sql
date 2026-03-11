
SELECT p.Id,
       p.Title,
       u.DisplayName,
       p.CreationDate
FROM
  (SELECT Id,
          Title,
          OwnerUserId,
          CreationDate
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.CreationDate DESC;