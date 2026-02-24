SELECT U.DisplayName, COUNT(P.Id) AS TotalPosts
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
GROUP BY U.DisplayName
ORDER BY TotalPosts DESC
LIMIT 10;
