
SELECT U.DisplayName,
       P.Title,
       P.CreationDate,
       P.Score,
       C.Text AS CommentText
FROM Users U
JOIN Posts P ON P.OwnerUserId = U.Id
LEFT JOIN Comments C ON P.Id = C.PostId
WHERE P.PostTypeId = 1
ORDER BY P.CreationDate DESC
LIMIT 10;