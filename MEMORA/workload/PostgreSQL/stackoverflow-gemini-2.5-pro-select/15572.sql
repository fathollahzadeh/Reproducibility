
SELECT P.Id AS PostId,
       P.Title,
       U.DisplayName AS OwnerDisplayName,
       P.CreationDate,
       P.Score,
       P.ViewCount
FROM
  (SELECT Id,
          Title,
          OwnerUserId,
          CreationDate,
          Score,
          ViewCount
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS P
JOIN Users U ON P.OwnerUserId = U.Id
ORDER BY P.CreationDate DESC;