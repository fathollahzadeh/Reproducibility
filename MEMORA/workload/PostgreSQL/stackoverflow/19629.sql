SELECT u.DisplayName, 
       COUNT(p.Id) AS PostCount, 
       SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
       SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
       AVG(u.Reputation) AS AverageReputation
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.DisplayName
ORDER BY PostCount DESC
LIMIT 10;
