
SELECT U.DisplayName,
       P_Limited.Title,
       P_Limited.CreationDate,
       P_Limited.Score
FROM
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          Score
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS P_Limited
JOIN Users U ON P_Limited.OwnerUserId = U.Id
ORDER BY P_Limited.CreationDate DESC;