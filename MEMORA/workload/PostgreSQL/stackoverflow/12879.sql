
SELECT
    p.PostTypeId,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation,
    MIN(p.CreationDate) AS EarliestPostDate,
    MAX(p.CreationDate) AS LatestPostDate
FROM
    Posts p
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
GROUP BY
    p.PostTypeId
ORDER BY
    TotalPosts DESC;
