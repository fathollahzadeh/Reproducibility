SELECT p.Id, p.Title, p.CreationDate, u.DisplayName, pt.Name as PostType
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE p.Score > 0
ORDER BY p.CreationDate DESC
LIMIT 10;
