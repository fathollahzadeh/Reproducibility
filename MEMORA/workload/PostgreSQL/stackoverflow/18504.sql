SELECT U.DisplayName, P.Title, P.Score
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.CreationDate >= '2023-01-01'
ORDER BY P.Score DESC
LIMIT 10;
