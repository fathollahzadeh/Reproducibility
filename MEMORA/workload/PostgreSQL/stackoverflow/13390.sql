WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Id, 0)) AS CommentCount
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
)

SELECT 
    us.UserId,
    us.BadgeCount,
    us.PostCount,
    us.TotalViews,
    us.TotalScore,
    us.CommentCount
FROM 
    UserStats us
ORDER BY 
    us.TotalScore DESC,
    us.TotalViews DESC
LIMIT 100;