WITH UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.HighestBadgeClass, 0) AS HighestBadgeClass,
    ps.PostCount,
    ps.TotalViews,
    ps.TotalScore,
    pt.TagName AS PopularTag
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
CROSS JOIN 
    PopularTags pt
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    ps.TotalViews DESC
LIMIT 50;