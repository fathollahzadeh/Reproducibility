SELECT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    AVG(p.ViewCount) AS AvgViewCount,
    MAX(p.CreationDate) AS LastPostDate
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
GROUP BY
    u.Id, u.DisplayName, u.Reputation
ORDER BY
    TotalScore DESC, PostCount DESC;