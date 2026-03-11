
SELECT U.DisplayName,
       P.Title,
       P.CreationDate,
       P.ViewCount,
       P.Score
FROM Users U
CROSS JOIN LATERAL
  (SELECT Title,
          CreationDate,
          ViewCount,
          Score
   FROM Posts
   WHERE OwnerUserId = U.Id
     AND PostTypeId = 1) P
ORDER BY P.CreationDate DESC
LIMIT 10;