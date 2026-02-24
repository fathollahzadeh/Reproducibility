WITH UserBadgeStats AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        ubs.UserId,
        ubs.DisplayName,
        ubs.BadgeCount,
        ubs.GoldBadges,
        ubs.SilverBadges,
        ubs.BronzeBadges,
        ps.PostCount,
        ps.Questions,
        ps.Answers,
        ps.TotalViews
    FROM 
        UserBadgeStats ubs
    LEFT JOIN 
        PostStats ps ON ubs.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(Questions, 0) AS Questions,
    COALESCE(Answers, 0) AS Answers,
    COALESCE(TotalViews, 0) AS TotalViews
FROM 
    UserPostBadgeStats
ORDER BY 
    BadgeCount DESC, TotalViews DESC
LIMIT 100;
