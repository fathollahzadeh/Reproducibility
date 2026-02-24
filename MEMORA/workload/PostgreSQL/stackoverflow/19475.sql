SELECT p.Id, p.Title, p.ViewCount, u.DisplayName, u.Reputation
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.PostTypeId = 1 
ORDER BY p.ViewCount DESC
LIMIT 10;