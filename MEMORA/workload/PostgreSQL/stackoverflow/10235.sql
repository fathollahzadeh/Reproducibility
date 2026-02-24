SELECT pt.Name as PostType, COUNT(p.Id) as PostCount
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY pt.Name;