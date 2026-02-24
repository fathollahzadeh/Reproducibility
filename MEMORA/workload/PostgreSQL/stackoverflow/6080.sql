
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (6, 12) THEN 1 ELSE 0 END) AS DeletedPostCount,
        SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.DeletedPostCount,
        ua.VoteCount,
        ua.CommentCount,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ua.AvgReputation
    FROM 
        UserActivity ua
    LEFT JOIN 
        UserBadges ub ON ua.UserId = ub.UserId
)
SELECT 
    fs.DisplayName,
    fs.PostCount,
    fs.QuestionCount,
    fs.AnswerCount,
    fs.DeletedPostCount,
    fs.VoteCount,
    fs.CommentCount,
    fs.BadgeCount,
    fs.GoldBadges,
    fs.SilverBadges,
    fs.BronzeBadges,
    fs.AvgReputation
FROM 
    FinalStats fs
ORDER BY 
    fs.PostCount DESC, fs.QuestionCount DESC, fs.VoteCount DESC
LIMIT 10;
