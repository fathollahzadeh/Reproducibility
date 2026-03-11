
SELECT U.DisplayName,
       P_Limited.Title,
       P_Limited.CreationDate,
       P_Limited.Score,
       P_Limited.ViewCount
FROM Users U
INNER JOIN
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS P_Limited ON U.Id = P_Limited.OwnerUserId;