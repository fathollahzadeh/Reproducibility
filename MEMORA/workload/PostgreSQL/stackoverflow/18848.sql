SELECT u.DisplayName, p.Title, p.CreationDate, pt.Name AS PostType
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE p.ViewCount > 1000
ORDER BY p.CreationDate DESC
LIMIT 10;
