SELECT
    COUNT(DISTINCT p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgPostScore,
    AVG(p.ViewCount) AS AvgViewCount,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM
    Posts p
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Badges b ON b.UserId = p.OwnerUserId
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.CreationDate >= '2021-01-01' 
    AND p.PostTypeId = 1 