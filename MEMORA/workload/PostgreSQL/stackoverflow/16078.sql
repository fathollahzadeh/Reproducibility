SELECT u.DisplayName, COUNT(b.Id) AS BadgeCount
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
GROUP BY u.DisplayName
ORDER BY BadgeCount DESC
LIMIT 10;
