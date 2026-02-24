WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserPerformance AS (
    SELECT 
        up.UserId,
        up.PostCount,
        up.CommentCount,
        up.TotalViews,
        up.TotalScore,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM 
        UserPostCounts up
    LEFT JOIN 
        BadgeCounts bc ON up.UserId = bc.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    up.PostCount,
    up.CommentCount,
    up.TotalViews,
    up.TotalScore,
    up.BadgeCount
FROM 
    Users u
JOIN 
    UserPerformance up ON u.Id = up.UserId
ORDER BY 
    up.TotalScore DESC, 
    up.PostCount DESC
LIMIT 100;