
WITH UserReputation AS (
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
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
), 

ReputationEnhancements AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation + COALESCE(ps.TotalPosts * 10, 0) + COALESCE(ps.AcceptedAnswers * 20, 0) AS EnhancedReputation
    FROM UserReputation ur
    LEFT JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
)

SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ps.TotalPosts,
    ps.QuestionCount,
    ps.AcceptedAnswers,
    rs.EnhancedReputation
FROM UserReputation ur
LEFT JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
JOIN ReputationEnhancements rs ON ur.UserId = rs.UserId
ORDER BY rs.EnhancedReputation DESC, ur.Reputation DESC;
