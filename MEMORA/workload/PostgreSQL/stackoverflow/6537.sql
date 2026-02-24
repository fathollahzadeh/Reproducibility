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

PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),

UserSummary AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        pa.PostCount,
        pa.Questions,
        pa.Answers,
        pa.TotalViews,
        pa.AverageScore
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostActivity pa ON ub.UserId = pa.OwnerUserId
)

SELECT 
    us.DisplayName,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.PostCount,
    us.Questions,
    us.Answers,
    us.TotalViews,
    us.AverageScore
FROM 
    UserSummary us
WHERE 
    us.BadgeCount > 0
ORDER BY 
    us.BadgeCount DESC, us.TotalViews DESC
LIMIT 10;
