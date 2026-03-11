
SELECT u.DisplayName,
       p_sub.Title,
       p_sub.CreationDate,
       p_sub.ViewCount,
       p_sub.Score
FROM
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          ViewCount,
          Score
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p_sub
JOIN Users u ON p_sub.OwnerUserId = u.Id
ORDER BY p_sub.CreationDate DESC;