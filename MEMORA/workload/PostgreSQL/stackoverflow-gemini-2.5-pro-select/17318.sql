
SELECT u.DisplayName,
       p.Title,
       p.CreationDate,
       p.Score
FROM Posts p
JOIN
  (SELECT Id
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY Score DESC
   LIMIT 10) AS top_ids ON p.Id = top_ids.Id
JOIN Users u ON p.OwnerUserId = u.Id
ORDER BY p.Score DESC;