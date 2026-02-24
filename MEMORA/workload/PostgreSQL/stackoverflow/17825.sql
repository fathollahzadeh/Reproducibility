
SELECT U.DisplayName, COUNT(P.Id) AS PostCount, SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Votes V ON P.Id = V.PostId
GROUP BY U.DisplayName
HAVING COUNT(P.Id) > 0
ORDER BY PostCount DESC;
