SELECT
    u.Id AS UserId,
    u.DisplayName,
    COUNT(a.Id) AS TotalAnswers,
    COUNT(c.Id) AS TotalComments,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1 
LEFT JOIN
    Comments c ON p.Id = c.PostId
WHERE
    u.Reputation > 0 
GROUP BY
    u.Id, u.DisplayName
ORDER BY
    TotalAnswers DESC, TotalViews DESC;