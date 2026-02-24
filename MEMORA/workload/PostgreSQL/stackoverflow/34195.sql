WITH RECURSIVE HighRankingUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM Users
    WHERE Reputation > 5000
    UNION ALL
    SELECT u.Id, u.DisplayName, u.Reputation
    FROM Users u
    INNER JOIN HighRankingUsers hru ON u.Id = hru.Id + 1 
    WHERE u.Reputation > 5000
),
UserBadges AS (
    SELECT b.UserId, COUNT(*) AS BadgeCount, 
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostInfo AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        ps.LastPostDate
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
),
HighlyActiveUsers AS (
    SELECT 
        u.DisplayName,
        u.BadgeCount, 
        u.TotalQuestions + u.TotalAnswers AS TotalPosts,
        RANK() OVER (ORDER BY u.TotalViews DESC) AS ViewRank
    FROM UserPostInfo u
    WHERE u.TotalQuestions + u.TotalAnswers > 10
)

SELECT 
    ha.DisplayName,
    ha.BadgeCount,
    ha.TotalPosts,
    ha.ViewRank,
    hru.Reputation AS HighRankReputation
FROM HighlyActiveUsers ha
LEFT JOIN HighRankingUsers hru ON ha.DisplayName = hru.DisplayName
ORDER BY ha.ViewRank, ha.TotalPosts DESC;