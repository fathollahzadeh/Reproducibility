SELECT U.DisplayName, COUNT(P.Id) AS PostCount, SUM(P.Score) AS TotalScore
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
GROUP BY U.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
