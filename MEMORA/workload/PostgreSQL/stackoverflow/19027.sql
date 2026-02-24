SELECT u.DisplayName, COUNT(p.Id) AS PostCount, SUM(COALESCE(p.Score, 0)) AS TotalScore
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
