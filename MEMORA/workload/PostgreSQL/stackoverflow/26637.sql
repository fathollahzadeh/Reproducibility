WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

PostStatistics AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),

UserPostMetrics AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges,
        COALESCE(p.PostCount, 0) AS PostCount,
        COALESCE(p.QuestionCount, 0) AS QuestionCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.AvgScore, 0) AS AvgScore,
        COALESCE(p.AvgViewCount, 0) AS AvgViewCount
    FROM UserStatistics u
    LEFT JOIN PostStatistics p ON u.UserId = p.UserId
)

SELECT 
    DisplayName,
    Reputation,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    QuestionCount,
    AnswerCount,
    AvgScore,
    AvgViewCount
FROM UserPostMetrics
ORDER BY Reputation DESC, BadgeCount DESC
LIMIT 100;

