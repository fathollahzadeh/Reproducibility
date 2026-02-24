SELECT U.DisplayName, COUNT(P.Id) AS PostCount
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
WHERE U.Reputation > 1000
GROUP BY U.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
