
WITH UserBadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
CombinedSummary AS (
    SELECT 
        ubs.UserId,
        ubs.DisplayName,
        ubs.BadgeCount,
        ubs.GoldBadges,
        ubs.SilverBadges,
        ubs.BronzeBadges,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalScore,
        ps.TotalViews
    FROM UserBadgeSummary ubs
    LEFT JOIN PostSummary ps ON ubs.UserId = ps.OwnerUserId
)
SELECT 
    c.DisplayName,
    c.BadgeCount,
    c.GoldBadges,
    c.SilverBadges,
    c.BronzeBadges,
    COALESCE(c.QuestionCount, 0) AS QuestionCount,
    COALESCE(c.AnswerCount, 0) AS AnswerCount,
    COALESCE(c.TotalScore, 0) AS TotalScore,
    COALESCE(c.TotalViews, 0) AS TotalViews
FROM CombinedSummary c
WHERE c.BadgeCount > 0
ORDER BY c.BadgeCount DESC, c.TotalScore DESC
LIMIT 10;
