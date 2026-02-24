WITH UserBadgeCount AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        COALESCE(ub.BadgeCount, 0) AS TotalBadges, 
        COALESCE(ps.PostCount, 0) AS TotalPosts,
        COALESCE(ps.QuestionCount, 0) AS TotalQuestions,
        COALESCE(ps.AnswerCount, 0) AS TotalAnswers,
        COALESCE(ps.AvgScore, 0) AS AvgPostScore
    FROM Users u
    LEFT JOIN UserBadgeCount ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
),
Ranking AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalBadges, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        AvgPostScore,
        RANK() OVER (ORDER BY TotalBadges DESC, TotalPosts DESC, AvgPostScore DESC) AS PerformanceRank
    FROM UserPerformance
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.TotalBadges,
    r.TotalPosts,
    r.TotalQuestions,
    r.TotalAnswers,
    r.AvgPostScore,
    r.PerformanceRank
FROM Ranking r
WHERE r.PerformanceRank <= 10
ORDER BY r.PerformanceRank;
