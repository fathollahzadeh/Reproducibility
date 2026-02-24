SELECT U.DisplayName, P.Title, P.CreationDate, COUNT(C.Id) AS CommentCount
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
LEFT JOIN Comments C ON P.Id = C.PostId
WHERE P.PostTypeId = 1
GROUP BY U.DisplayName, P.Title, P.CreationDate
ORDER BY CommentCount DESC
LIMIT 10;
