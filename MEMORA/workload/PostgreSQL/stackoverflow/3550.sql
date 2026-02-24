WITH UserBadges AS (
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
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserScores AS (
   SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(pm.PostCount, 0) AS PostCount,
        COALESCE(pm.QuestionCount, 0) AS QuestionCount,
        COALESCE(pm.AnswerCount, 0) AS AnswerCount,
        COALESCE(pm.AverageScore, 0) AS AverageScore,
        COALESCE(pm.LastPostDate, '1900-01-01') AS LastPostDate
   FROM Users u
   LEFT JOIN UserBadges ub ON u.Id = ub.UserId
   LEFT JOIN PostMetrics pm ON u.Id = pm.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.BadgeCount,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.AverageScore,
    DENSE_RANK() OVER (ORDER BY u.AverageScore DESC) AS ScoreRank,
    CASE 
        WHEN u.PostCount = 0 THEN 'No Posts'
        WHEN u.AverageScore > 10 THEN 'Highly Active'
        ELSE 'Moderately Active'
    END AS ActivityLevel
FROM UserScores u
WHERE u.BadgeCount > 0 OR u.PostCount > 0
ORDER BY u.AverageScore DESC, u.BadgeCount DESC
LIMIT 10;
