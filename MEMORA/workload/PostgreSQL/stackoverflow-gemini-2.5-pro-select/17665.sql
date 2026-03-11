
SELECT u.DisplayName,
       p_top.Title,
       p_top.CreationDate,
       p_top.Score
FROM
  (SELECT p.OwnerUserId,
          p.Title,
          p.CreationDate,
          p.Score
   FROM Posts p
   WHERE p.PostTypeId = 1
   ORDER BY p.Score DESC
   LIMIT 10) AS p_top
JOIN Users u ON p_top.OwnerUserId = u.Id
ORDER BY p_top.Score DESC;