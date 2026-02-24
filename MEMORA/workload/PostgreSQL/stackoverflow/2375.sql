WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
UserPosts AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ba.BadgeCount,
        ba.GoldBadges,
        ba.SilverBadges,
        ba.BronzeBadges,
        ua.PostCount,
        ua.TotalViews,
        ua.QuestionCount,
        ua.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY ua.Reputation DESC) AS UserRank
    FROM UserActivity ua
    LEFT JOIN UserBadges ba ON ua.UserId = ba.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(u.BadgeCount, 0) AS BadgeCount,
    COALESCE(u.GoldBadges, 0) AS GoldBadges,
    COALESCE(u.SilverBadges, 0) AS SilverBadges,
    COALESCE(u.BronzeBadges, 0) AS BronzeBadges,
    u.PostCount,
    u.TotalViews,
    u.QuestionCount,
    u.AnswerCount,
    u.UserRank,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Count > 10) AS PopularTags
FROM UserPosts u
WHERE u.PostCount > 5
  AND u.Reputation > 50
  AND (u.QuestionCount + u.AnswerCount) > 10
ORDER BY u.Reputation DESC, u.PostCount DESC;

