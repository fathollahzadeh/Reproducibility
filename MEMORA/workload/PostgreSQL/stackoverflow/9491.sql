WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AverageScore, 0) AS AverageScore,
        ub.BadgeCount,
        ub.GoldCount,
        ub.SilverCount,
        ub.BronzeCount
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    up.DisplayName,
    up.PostCount,
    up.TotalViews,
    up.TotalScore,
    up.AverageScore,
    up.BadgeCount,
    up.GoldCount,
    up.SilverCount,
    up.BronzeCount
FROM 
    UserPerformance up
ORDER BY 
    up.TotalScore DESC,
    up.TotalViews DESC,
    up.PostCount DESC
LIMIT 10;