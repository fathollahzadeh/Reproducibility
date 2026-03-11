
SELECT U.DisplayName,
       P_limited.Title,
       P_limited.CreationDate,
       P_limited.ViewCount,
       P_limited.Score
FROM
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          ViewCount,
          Score
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS P_limited
JOIN Users U ON P_limited.OwnerUserId = U.Id
ORDER BY P_limited.CreationDate DESC;