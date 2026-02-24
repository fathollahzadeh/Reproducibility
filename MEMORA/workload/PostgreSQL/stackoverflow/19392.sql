SELECT U.DisplayName, COUNT(P.Id) AS PostCount, SUM(V.BountyAmount) AS TotalBounties
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Votes V ON P.Id = V.PostId
WHERE U.Reputation > 1000
GROUP BY U.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
