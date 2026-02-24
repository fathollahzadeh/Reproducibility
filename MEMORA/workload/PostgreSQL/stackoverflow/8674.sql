
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
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        UserBadges
),
ActivePosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ap.PostCount, 0) AS PostCount,
        COALESCE(ap.TotalScore, 0) AS TotalScore,
        COALESCE(ap.TotalViews, 0) AS TotalViews,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        ActivePosts ap ON u.Id = ap.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
),
FinalResults AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.PostCount,
        up.TotalScore,
        up.TotalViews,
        up.BadgeCount,
        up.GoldBadges,
        up.SilverBadges,
        up.BronzeBadges,
        t.BadgeRank
    FROM 
        UserPerformance up
    LEFT JOIN 
        TopUsers t ON up.UserId = t.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    BadgeRank
FROM 
    FinalResults
WHERE 
    BadgeRank IS NOT NULL
ORDER BY 
    BadgeRank;
