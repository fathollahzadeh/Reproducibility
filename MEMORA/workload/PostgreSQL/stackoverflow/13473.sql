SELECT
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    SUM(u.Reputation) AS TotalReputation,
    AVG(u.Views) AS AverageViews,
    MAX(p.CreationDate) AS LatestPostDate
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    u.Id, u.DisplayName
ORDER BY
    TotalPosts DESC, TotalReputation DESC
LIMIT 100;