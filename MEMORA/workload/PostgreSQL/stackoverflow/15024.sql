SELECT u.DisplayName, p.Title, p.CreationDate, p.Score
FROM Users AS u
JOIN Posts AS p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1 
ORDER BY p.CreationDate DESC
LIMIT 10;