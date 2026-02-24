
WITH UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
UserPostActivity AS (
    SELECT 
        u.UserId,
        COUNT(DISTINCT ap.PostId) AS ActivePostCount,
        SUM(COALESCE(ap.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(ap.Score, 0)) AS TotalScore
    FROM 
        UsersWithBadges u
    LEFT JOIN 
        ActivePosts ap ON u.UserId = ap.OwnerUserId
    GROUP BY 
        u.UserId
)
SELECT 
    ub.DisplayName,
    ub.BadgeCount,
    COALESCE(upa.ActivePostCount, 0) AS ActivePostCount,
    COALESCE(upa.TotalViews, 0) AS TotalViews,
    COALESCE(upa.TotalScore, 0) AS TotalScore
FROM 
    UsersWithBadges ub
LEFT JOIN 
    UserPostActivity upa ON ub.UserId = upa.UserId
ORDER BY 
    ub.BadgeCount DESC,
    TotalViews DESC,
    TotalScore DESC
LIMIT 10;
