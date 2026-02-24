
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ub.GoldCount, 0) AS TotalGold,
        COALESCE(ub.SilverCount, 0) AS TotalSilver,
        COALESCE(ub.BronzeCount, 0) AS TotalBronze,
        COALESCE(ps.PostCount, 0) AS TotalPosts,
        COALESCE(ps.QuestionCount, 0) AS TotalQuestions,
        COALESCE(ps.AnswerCount, 0) AS TotalAnswers,
        COALESCE(ps.TotalScore, 0) AS TotalScore
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    DisplayName,
    Reputation,
    TotalBadges,
    TotalGold,
    TotalSilver,
    TotalBronze,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore
FROM CombinedStats
ORDER BY Reputation DESC, TotalScore DESC
LIMIT 10;
