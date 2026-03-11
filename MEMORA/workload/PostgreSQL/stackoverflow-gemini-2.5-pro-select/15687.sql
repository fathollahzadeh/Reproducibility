
SELECT P.Id AS PostId,
       P.Title,
       U.DisplayName AS OwnerDisplayName,
       P.CreationDate,
       P.Score,
       P.ViewCount
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
JOIN
  (SELECT Id
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS LimitedP ON P.Id = LimitedP.Id
ORDER BY P.CreationDate DESC;