SELECT U.DisplayName, P.Title, P.CreationDate
FROM Posts AS P
JOIN Users AS U ON P.OwnerUserId = U.Id
WHERE P.PostTypeId = 1
ORDER BY P.CreationDate DESC
LIMIT 10;
