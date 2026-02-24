SELECT P.Title, U.DisplayName, P.CreationDate, P.Score
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.ViewCount > 1000
ORDER BY P.CreationDate DESC
LIMIT 10;
