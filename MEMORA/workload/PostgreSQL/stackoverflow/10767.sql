SELECT
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY
    pt.Name
ORDER BY
    TotalPosts DESC;