WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        Users.Id, 
        Users.DisplayName, 
        COALESCE(ub.BadgeCount, 0) AS BadgeCount, 
        COALESCE(ps.PostCount, 0) AS PostCount, 
        COALESCE(ps.TotalScore, 0) AS TotalScore, 
        COALESCE(ps.AverageViews, 0) AS AverageViews
    FROM 
        Users
    LEFT JOIN 
        UserBadgeCounts ub ON Users.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON Users.Id = ps.OwnerUserId
)
SELECT 
    au.Id,
    au.DisplayName,
    au.BadgeCount,
    au.PostCount,
    au.TotalScore,
    au.AverageViews
FROM 
    ActiveUsers au
WHERE 
    au.BadgeCount > 0 
    AND au.PostCount > 3 
ORDER BY 
    au.TotalScore DESC, 
    au.AverageViews DESC
LIMIT 10;