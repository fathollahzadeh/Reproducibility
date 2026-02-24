WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
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
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        bs.BadgeCount,
        bs.GoldBadges,
        bs.SilverBadges,
        bs.BronzeBadges,
        ps.PostCount,
        ps.AvgScore,
        ps.TotalViews,
        ROW_NUMBER() OVER (ORDER BY ps.PostCount DESC, bs.BadgeCount DESC) AS Ranking
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats bs ON u.Id = bs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    AvgScore,
    TotalViews,
    Ranking
FROM 
    UserPerformance
WHERE 
    Ranking <= 10
ORDER BY 
    Ranking;