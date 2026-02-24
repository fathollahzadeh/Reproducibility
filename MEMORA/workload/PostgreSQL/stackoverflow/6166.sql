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
TopBadgedUsers AS (
    SELECT 
        UserId, 
        BadgeCount
    FROM 
        UserBadgeCounts 
    WHERE 
        BadgeCount > 0
    ORDER BY 
        BadgeCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostMetrics AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AverageViewCount, 0) AS AverageViewCount,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts bc ON u.Id = bc.UserId
)
SELECT 
    u.DisplayName,
    upm.PostCount,
    upm.TotalScore,
    upm.AverageViewCount,
    upm.BadgeCount
FROM 
    UserPostMetrics upm
JOIN 
    TopBadgedUsers tbu ON upm.UserId = tbu.UserId
JOIN 
    Users u ON upm.UserId = u.Id
ORDER BY 
    upm.BadgeCount DESC,
    upm.TotalScore DESC;
