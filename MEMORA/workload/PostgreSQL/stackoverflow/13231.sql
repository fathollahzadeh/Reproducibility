SELECT PostTypeId, COUNT(*) AS PostCount
FROM Posts
GROUP BY PostTypeId
ORDER BY PostCount DESC;