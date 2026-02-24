
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS PostsWithHighViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostHistoryCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.UserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalAnswers,
        us.TotalQuestions,
        us.PositiveScoredPosts,
        us.PostsWithHighViews,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(phc.HistoryCount, 0) AS HistoryCount,
        phc.LastEditDate
    FROM UserStats us
    LEFT JOIN BadgeCounts bc ON us.UserId = bc.UserId
    LEFT JOIN PostHistoryCounts phc ON us.UserId = phc.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    PositiveScoredPosts,
    PostsWithHighViews,
    BadgeCount,
    HistoryCount,
    LastEditDate
FROM CombinedStats
WHERE TotalPosts > 10
ORDER BY TotalPosts DESC, PositiveScoredPosts DESC
LIMIT 50;
