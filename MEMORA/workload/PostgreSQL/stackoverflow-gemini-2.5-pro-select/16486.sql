WITH TopPostIds AS
  (SELECT Id
   FROM Posts
   WHERE PostTypeId = 1
   ORDER BY CreationDate DESC
   LIMIT 10)
SELECT U.DisplayName,
       P.Title,
       P.CreationDate,
       P.Score
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.Id IN
    (SELECT Id
     FROM TopPostIds)
ORDER BY P.CreationDate DESC;