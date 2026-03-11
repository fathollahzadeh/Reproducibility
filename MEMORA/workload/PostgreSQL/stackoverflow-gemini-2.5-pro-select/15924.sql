
SELECT U.DisplayName,
       P_Limited.Title,
       P_Limited.CreationDate,
       P_Limited.Score,
       P_Limited.ViewCount
FROM
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS P_Limited
LEFT JOIN Users U ON P_Limited.OwnerUserId = U.Id;