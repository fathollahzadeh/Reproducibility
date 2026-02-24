WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id,
        COALESCE(ub.TotalBadges, 0) AS BadgeCount,
        COALESCE(ps.TotalPosts, 0) AS UserPostCount,
        COALESCE(ps.TotalQuestions, 0) AS UserQuestionCount,
        COALESCE(ps.TotalAnswers, 0) AS UserAnswerCount,
        COALESCE(ps.TotalScore, 0) AS UserTotalScore,
        COALESCE(ps.TotalViews, 0) AS UserTotalViews,
        u.Reputation,
        u.CreationDate,
        u.DisplayName
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
RankedUsers AS (
    SELECT 
        ua.*,
        RANK() OVER (ORDER BY ua.Reputation DESC, ua.BadgeCount DESC, ua.UserTotalScore DESC) AS UserRank
    FROM UserActivity ua
)
SELECT 
    r.UserRank,
    r.DisplayName,
    r.Reputation,
    r.BadgeCount,
    r.UserPostCount,
    r.UserQuestionCount,
    r.UserAnswerCount,
    r.UserTotalScore,
    r.UserTotalViews,
    r.CreationDate
FROM RankedUsers r
WHERE r.UserRank <= 100
ORDER BY r.UserRank;
