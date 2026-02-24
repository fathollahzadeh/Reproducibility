WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPostCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldCount,
        ub.SilverCount,
        ub.BronzeCount,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.PopularPostCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        UserPostStats ups ON u.Id = ups.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.BadgeCount,
    ua.GoldCount,
    ua.SilverCount,
    ua.BronzeCount,
    COALESCE(ua.PostCount, 0) AS PostCount,
    COALESCE(ua.QuestionCount, 0) AS QuestionCount,
    COALESCE(ua.AnswerCount, 0) AS AnswerCount,
    COALESCE(ua.PopularPostCount, 0) AS PopularPostCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = ua.UserId AND v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') AS RecentVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = ua.UserId AND c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') AS RecentComments
FROM 
    UserActivity ua
ORDER BY 
    ua.BadgeCount DESC, 
    ua.PostCount DESC
LIMIT 10;