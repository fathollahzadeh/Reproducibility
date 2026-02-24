SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COALESCE(SUM(p.Score), 0) AS TotalScore,
    COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
    MAX(p.CreationDate) AS MostRecentPostDate,
    MIN(p.CreationDate) AS FirstPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;