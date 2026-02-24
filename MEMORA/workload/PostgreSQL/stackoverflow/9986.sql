WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
PerformanceBenchmark AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        tp.PostCount,
        tp.TotalViews,
        tp.AverageScore,
        RANK() OVER (ORDER BY tp.TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY tp.PostCount DESC) AS PostRank
    FROM 
        UserBadges ub
    LEFT JOIN 
        TopPosts tp ON ub.UserId = tp.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    TotalViews,
    AverageScore,
    ViewRank,
    PostRank
FROM 
    PerformanceBenchmark
WHERE 
    BadgeCount > 0
ORDER BY 
    BadgeCount DESC, TotalViews DESC
LIMIT 10;