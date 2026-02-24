
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation, u.CreationDate
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
CombinedStats AS (
    SELECT 
        u.UserId,
        u.Reputation,
        u.CreationDate,
        u.PostCount,
        u.QuestionCount,
        u.AnswerCount,
        u.TotalViews,
        u.TotalScore,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges
    FROM UserStats u
    LEFT JOIN BadgeStats b ON u.UserId = b.UserId
)
SELECT 
    UserId,
    Reputation,
    CreationDate,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM CombinedStats
ORDER BY Reputation DESC
FETCH FIRST 10 ROWS ONLY;
