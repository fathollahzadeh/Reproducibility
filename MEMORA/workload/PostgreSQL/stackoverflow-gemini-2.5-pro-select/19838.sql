
SELECT U.DisplayName,
       P.Title,
       P.CreationDate,
       P.Score
FROM
  (SELECT OwnerUserId,
          Title,
          CreationDate,
          Score
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS P
JOIN Users U ON P.OwnerUserId = U.Id
ORDER BY P.CreationDate DESC;