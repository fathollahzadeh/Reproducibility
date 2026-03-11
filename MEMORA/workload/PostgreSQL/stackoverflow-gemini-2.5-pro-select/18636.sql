
SELECT U.DisplayName,
       P.Title,
       P.CreationDate,
       P.ViewCount,
       P.Score
FROM
  (SELECT Id,
          OwnerUserId
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10) AS LimitedPostKeys
JOIN Posts P ON LimitedPostKeys.Id = P.Id
JOIN Users U ON P.OwnerUserId = U.Id
ORDER BY P.CreationDate DESC;