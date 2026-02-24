SELECT p.Title, p.CreationDate, u.DisplayName, pt.Name AS PostTypeName
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN PostTypes pt ON p.PostTypeId = pt.Id
ORDER BY p.CreationDate DESC
LIMIT 10;
