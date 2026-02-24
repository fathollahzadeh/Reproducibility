SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    MAX(p.CreationDate) AS LastPostDate,
    MAX(c.CreationDate) AS LastCommentDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC, CommentCount DESC;