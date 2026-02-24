SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostsCount,
    COUNT(DISTINCT a.Id) AS AnswersCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    SUM(COALESCE(p.Score, 0)) AS TotalScore,
    SUM(COALESCE(c.Id, 0)) AS CommentsCount,
    COUNT(DISTINCT b.Id) AS BadgesCount,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalViews DESC, TotalScore DESC
LIMIT 100;