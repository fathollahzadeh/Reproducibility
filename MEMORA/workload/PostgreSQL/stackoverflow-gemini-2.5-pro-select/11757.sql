
SELECT pt.Name AS PostType,
       COUNT(p.Id) AS TotalPosts,
       AVG(p.Score) AS AverageScore,
       AVG(p.ViewCount) AS AverageViewCount
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name
HAVING COUNT(p.Id) > 0
ORDER BY TotalPosts DESC;