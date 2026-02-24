WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        0 AS BadgeCount,
        0 AS PostCount,
        0 AS AnswerCount
    FROM Users u
    WHERE u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.Reputation, u.CreationDate, u.DisplayName
),

AggregatedPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    WHERE p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),

UserPerformance AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.CreationDate,
        us.BadgeCount,
        aps.TotalPosts,
        aps.TotalScore,
        aps.AvgViews,
        aps.LastPostDate
    FROM RecursiveUserStats us
    LEFT JOIN AggregatedPostStats aps ON us.UserId = aps.OwnerUserId
),

RankedUsers AS (
    SELECT 
        up.*,
        ROW_NUMBER() OVER (ORDER BY up.Reputation DESC) AS Rank
    FROM UserPerformance up
)

SELECT 
    ru.Rank,
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.BadgeCount,
    COALESCE(ru.TotalPosts, 0) AS TotalPosts,
    COALESCE(ru.TotalScore, 0) AS TotalScore,
    COALESCE(ru.AvgViews, 0) AS AvgViews,
    ru.LastPostDate
FROM RankedUsers ru
WHERE ru.BadgeCount > 5
OR (ru.TotalPosts > 10 AND ru.TotalScore > 100)
ORDER BY ru.Rank;