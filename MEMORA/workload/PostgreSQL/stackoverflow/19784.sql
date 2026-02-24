SELECT p.Id, p.Title, p.CreationDate, u.DisplayName, pt.Name AS PostType
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE p.ViewCount > 100
ORDER BY p.CreationDate DESC
LIMIT 10;
