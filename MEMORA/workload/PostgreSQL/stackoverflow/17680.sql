SELECT U.DisplayName, P.Title, P.CreationDate, P.Score
FROM Users AS U
JOIN Posts AS P ON U.Id = P.OwnerUserId
WHERE P.PostTypeId = 1
ORDER BY P.CreationDate DESC
LIMIT 10;
