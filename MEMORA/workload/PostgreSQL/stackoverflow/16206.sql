SELECT P.Id, P.Title, U.DisplayName, P.CreationDate
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.PostTypeId = 1
ORDER BY P.CreationDate DESC
LIMIT 10;
