SELECT u.DisplayName, COUNT(DISTINCT p.Id) AS PostCount
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
