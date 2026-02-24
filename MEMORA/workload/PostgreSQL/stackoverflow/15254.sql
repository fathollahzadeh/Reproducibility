SELECT u.DisplayName, p.Title, p.CreationDate, p.ViewCount
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE p.PostTypeId = 1
ORDER BY p.ViewCount DESC
LIMIT 10;
