WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalScore, 0) AS TotalScore
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStatistics ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    u.DisplayName,
    ups.Reputation,
    ups.BadgeCount,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    ups.PostCount,
    ups.Questions,
    ups.Answers,
    ups.TotalViews,
    ups.TotalScore
FROM 
    Users u
JOIN 
    UserPostStats ups ON u.Id = ups.UserId
WHERE 
    ups.PostCount > 0
ORDER BY 
    ups.TotalScore DESC, ups.Reputation DESC
LIMIT 10;
