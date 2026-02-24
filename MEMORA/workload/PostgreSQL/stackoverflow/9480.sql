WITH UserBadgeCounts AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AverageAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AverageAnswers, 0) AS AverageAnswers,
        COALESCE(ps.LastPostDate, '1900-01-01') AS LastPostDate
    FROM Users u
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.BadgeCount,
    up.PostCount,
    up.TotalScore,
    up.TotalViews,
    up.AverageAnswers,
    up.LastPostDate,
    DENSE_RANK() OVER (ORDER BY up.TotalScore DESC) AS RankByScore,
    DENSE_RANK() OVER (ORDER BY up.BadgeCount DESC) AS RankByBadges
FROM UserPerformance up
WHERE up.BadgeCount > 0 OR up.PostCount > 0
ORDER BY up.TotalScore DESC, up.LastPostDate DESC;
