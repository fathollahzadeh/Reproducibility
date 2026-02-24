WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
), UserSummaries AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        RANK() OVER (ORDER BY COALESCE(ps.TotalScore, 0) DESC) AS ScoreRank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    us.DisplayName,
    us.BadgeCount,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalScore,
    us.ScoreRank,
    COALESCE(pht.Name, 'No Activity') AS RecentActivity,
    COALESCE(MAX(ph.CreationDate), '1900-01-01') AS LastActivityDate
FROM UserSummaries us
LEFT JOIN Posts p ON us.Id = p.OwnerUserId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    us.DisplayName, us.BadgeCount, us.QuestionCount, us.AnswerCount, us.TotalScore, us.ScoreRank, pht.Name
HAVING 
    us.BadgeCount > 0 OR us.QuestionCount > 0
ORDER BY 
    us.ScoreRank ASC, us.DisplayName ASC;
