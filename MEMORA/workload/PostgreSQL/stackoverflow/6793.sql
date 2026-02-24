WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpvotedPosts,
        RANK() OVER (ORDER BY Reputation DESC) AS RankReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS RankPostCount
    FROM UserStats
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    ts.Reputation,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.UpvotedPosts,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount,
    ts.RankReputation,
    ts.RankPostCount
FROM TopUsers ts
JOIN Users u ON ts.UserId = u.Id
LEFT JOIN UserBadges ub ON ts.UserId = ub.UserId
WHERE ts.RankReputation <= 10 OR ts.RankPostCount <= 10
ORDER BY ts.RankReputation, ts.RankPostCount;
