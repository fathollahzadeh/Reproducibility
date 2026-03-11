
SELECT U.DisplayName,
       P.Title,
       P.CreationDate,
       P.Score,
       C.Text AS CommentText
FROM Posts P
LEFT JOIN Comments C ON P.Id = C.PostId
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.PostTypeId = 1
ORDER BY P.CreationDate DESC
LIMIT 10;