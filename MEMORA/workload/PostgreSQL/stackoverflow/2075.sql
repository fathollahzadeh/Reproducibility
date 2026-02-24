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
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        p.Id, 
        p.OwnerUserId, 
        p.Title, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate IS NOT NULL
)
SELECT 
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ps.Questions, 0) AS TotalQuestions,
    COALESCE(ps.Answers, 0) AS TotalAnswers,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    rp.Title AS MostRecentPostTitle,
    rp.CreationDate AS MostRecentPostDate
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
WHERE u.Reputation > (
        SELECT AVG(Reputation) 
        FROM Users 
        WHERE Reputation IS NOT NULL
    )
ORDER BY u.Reputation DESC, TotalBadges DESC;
