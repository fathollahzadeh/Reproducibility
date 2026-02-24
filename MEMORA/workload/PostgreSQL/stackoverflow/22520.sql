WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserPostStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, ub.BadgeNames, ub.BadgeCount
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeNames,
    up.TotalBadges,
    SUM(rp.ViewCount) AS TotalPostViews,
    SUM(CASE WHEN rp.PostRank = 1 THEN 1 ELSE 0 END) AS TopPosts,
    MAX(rp.Score) AS MaxPostScore,
    MIN(rp.CreationDate) AS FirstPostDate,
    MAX(rp.CreationDate) AS LastPostDate,
    COUNT(DISTINCT CASE WHEN rp.ViewCount > 50 THEN rp.PostId END) AS HighViewPosts
FROM 
    UserPostStatistics up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
GROUP BY 
    up.UserId, up.DisplayName, up.BadgeNames, up.TotalBadges
HAVING 
    SUM(rp.ViewCount) IS NOT NULL
    AND COUNT(rp.PostId) > 0
ORDER BY 
    TotalPostViews DESC, up.UserId ASC;