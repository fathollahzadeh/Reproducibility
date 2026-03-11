
SELECT p_sub.Title,
       p_sub.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       p_sub.Score,
       p_sub.ViewCount
FROM
  (SELECT Title,
          CreationDate,
          OwnerUserId,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p_sub
JOIN Users u ON p_sub.OwnerUserId = u.Id
ORDER BY p_sub.CreationDate DESC;