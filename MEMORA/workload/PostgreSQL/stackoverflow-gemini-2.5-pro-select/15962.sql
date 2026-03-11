
SELECT p.Id,
       p.Title,
       p.CreationDate,
       u.DisplayName,
       p.Score
FROM
  (SELECT Id,
          Title,
          CreationDate,
          OwnerUserId,
          Score
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p
JOIN Users u ON p.OwnerUserId = u.Id;