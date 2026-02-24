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
    GROUP BY u.Id
),
UserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        up.PostCount,
        up.QuestionCount,
        up.AnswerCount
    FROM Users u
    JOIN UserBadges ub ON u.Id = ub.UserId
    JOIN UserPosts up ON u.Id = up.OwnerUserId
    WHERE u.Reputation > 1000
)
SELECT 
    au.DisplayName,
    au.BadgeCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    au.PostCount,
    au.QuestionCount,
    au.AnswerCount
FROM ActiveUsers au
ORDER BY au.BadgeCount DESC, au.PostCount DESC
LIMIT 10;