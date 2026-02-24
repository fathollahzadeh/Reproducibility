
WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RankedPosts AS (
    SELECT
        ps.OwnerUserId,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ps.TotalScore DESC) AS PostRank
    FROM PostStats ps
    WHERE ps.PostCount > 0
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    COALESCE(rp.PostCount, 0) AS PostCount,
    COALESCE(rp.QuestionCount, 0) AS QuestionCount,
    COALESCE(rp.AnswerCount, 0) AS AnswerCount,
    COALESCE(rp.TotalScore, 0) AS TotalScore,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM UserBadges ub
LEFT JOIN RankedPosts rp ON ub.UserId = rp.OwnerUserId
WHERE ub.BadgeCount > 5
ORDER BY TotalScore DESC, PostCount DESC
LIMIT 10;
