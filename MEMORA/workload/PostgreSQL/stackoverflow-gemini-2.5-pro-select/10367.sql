
SELECT pt.Name AS PostType,
       COUNT(p.Id) AS TotalPosts,
       AVG(p.Score) AS AverageScore,
       SUM(p.ViewCount) AS TotalViews
FROM Posts p
CROSS JOIN PostTypes pt
WHERE p.PostTypeId = pt.Id
GROUP BY pt.Name
ORDER BY TotalPosts DESC;