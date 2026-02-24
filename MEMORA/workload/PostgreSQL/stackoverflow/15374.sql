SELECT u.DisplayName, COUNT(p.Id) AS TotalPosts
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.DisplayName
ORDER BY TotalPosts DESC
LIMIT 10;
