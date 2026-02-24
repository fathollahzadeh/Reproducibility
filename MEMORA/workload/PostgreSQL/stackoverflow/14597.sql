SELECT PostTypeId, COUNT(*) AS PostCount
FROM Posts
GROUP BY PostTypeId;