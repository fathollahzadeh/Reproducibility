
SELECT p_limited.Title,
       u.DisplayName AS OWNER,
       p_limited.CreationDate,
       p_limited.Score,
       p_limited.ViewCount
FROM
  (SELECT Title,
          OwnerUserId,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS p_limited
JOIN Users u ON p_limited.OwnerUserId = u.Id;