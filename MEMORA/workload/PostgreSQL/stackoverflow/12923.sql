WITH UserPostCount AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadgeCount AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    upc.PostCount,
    upc.TotalViews,
    upc.TotalScore,
    ubc.BadgeCount
FROM 
    Users u
JOIN 
    UserPostCount upc ON u.Id = upc.UserId
LEFT JOIN 
    UserBadgeCount ubc ON u.Id = ubc.UserId
ORDER BY 
    upc.TotalScore DESC, 
    upc.PostCount DESC;