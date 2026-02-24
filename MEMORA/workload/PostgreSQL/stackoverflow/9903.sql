WITH UserBadges AS (
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
), UserPosts AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.OwnerUserId
), UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        up.PostCount,
        up.Questions,
        up.Answers,
        up.TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        UserPosts up ON u.Id = up.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(GoldBadges, 0) AS GoldBadges,
    COALESCE(SilverBadges, 0) AS SilverBadges,
    COALESCE(BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(Questions, 0) AS Questions,
    COALESCE(Answers, 0) AS Answers,
    COALESCE(TotalScore, 0) AS TotalScore
FROM 
    UserActivity
ORDER BY 
    TotalScore DESC, 
    BadgeCount DESC
LIMIT 10;
