WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPerformances AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalScore, 0) AS TotalScore
    FROM Users u
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    DisplayName,
    Reputation,
    BadgeCount,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    (TotalScore / NULLIF(TotalPosts, 0)) AS AverageScorePerPost
FROM UserPerformances
WHERE Reputation > 1000
ORDER BY TotalScore DESC, BadgeCount DESC
LIMIT 50;
