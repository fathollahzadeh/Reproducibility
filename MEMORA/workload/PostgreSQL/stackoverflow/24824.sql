WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.ParentId) AS AnsweredQuestions,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.AnsweredQuestions, 0) AS AnsweredQuestions,
        COALESCE(ps.Questions, 0) AS QuestionsPosted,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN PostAggregates ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadgeStats bs ON u.Id = bs.UserId
    WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users) 
      AND u.LastAccessDate = (SELECT MAX(LastAccessDate) FROM Users) 
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.AnsweredQuestions,
    ua.QuestionsPosted,
    ua.BadgeCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    CASE WHEN ua.AnsweredQuestions > 0 THEN 'Active Contributor' ELSE 'Lurker' END AS UserStatus,
    CASE 
        WHEN ua.BadgeCount = 0 THEN 'No Badges'
        WHEN ua.BadgeCount BETWEEN 1 AND 3 THEN 'Novice'
        WHEN ua.BadgeCount BETWEEN 4 AND 10 THEN 'Intermediate'
        ELSE 'Expert'
    END AS BadgeLevel
FROM UserActivity ua
ORDER BY ua.TotalPosts DESC
LIMIT 10
OFFSET 0;