WITH BadgeSummary AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        SUM(ViewCount) AS TotalViews,
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(CASE WHEN Score IS NOT NULL THEN Score ELSE 0 END) AS AverageScore
    FROM Posts
    GROUP BY OwnerUserId
),
CloseReasons AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CASE 
            WHEN ph.Comment IS NULL THEN 'No comment' 
            ELSE ph.Comment 
        END, '; ') AS CloseComments
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.UserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(bs.TotalBadges, 0) AS UserBadges,
        COALESCE(ps.TotalViews, 0) AS UserTotalViews,
        COALESCE(ps.TotalPosts, 0) AS UserTotalPosts,
        COALESCE(ps.TotalQuestions, 0) AS UserTotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS UserTotalAnswers,
        COALESCE(ps.AverageScore, 0) AS UserAverageScore,
        COALESCE(cr.CloseCount, 0) AS UserCloseCount,
        COALESCE(cr.CloseComments, 'No closures') AS UserCloseComments
    FROM Users u
    LEFT JOIN BadgeSummary bs ON u.Id = bs.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN CloseReasons cr ON u.Id = cr.UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.UserBadges,
    up.UserTotalViews,
    up.UserTotalPosts,
    up.UserTotalQuestions,
    up.UserTotalAnswers,
    up.UserAverageScore,
    up.UserCloseCount,
    up.UserCloseComments,
    ROW_NUMBER() OVER (ORDER BY up.UserTotalPosts DESC) AS PerformanceRank,
    CASE 
        WHEN up.UserAverageScore > 10 THEN 'High Performer'
        WHEN up.UserAverageScore BETWEEN 5 AND 10 THEN 'Moderate Performer'
        ELSE 'Needs Improvement' 
    END AS PerformanceCategory
FROM UserPerformance up
WHERE up.UserCloseCount < 10
ORDER BY up.UserTotalViews DESC, up.UserBadges DESC
LIMIT 100;