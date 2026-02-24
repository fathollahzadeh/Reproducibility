WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN b.Name IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
UserActivityAnalytics AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalViews,
        ups.TotalBadges,
        ups.LastPostDate,
        COALESCE(MAX(ph.CreationDate), '1970-01-01') AS LastEditDate,
        COUNT(DISTINCT ph.Id) AS TotalEdits
    FROM UserPostStatistics ups
    LEFT JOIN PostHistory ph ON ups.UserId = ph.UserId
    GROUP BY ups.UserId, ups.DisplayName, ups.TotalPosts, ups.TotalQuestions, ups.TotalAnswers, ups.TotalViews, ups.TotalBadges, ups.LastPostDate
),
RankedUserStatistics AS (
    SELECT 
        ua.*,
        ROW_NUMBER() OVER (ORDER BY ua.TotalPosts DESC, ua.TotalViews DESC) AS UserRanking
    FROM UserActivityAnalytics ua
)

SELECT 
    rus.UserId,
    rus.DisplayName,
    rus.TotalPosts,
    rus.TotalQuestions,
    rus.TotalAnswers,
    rus.TotalViews,
    rus.TotalBadges,
    rus.LastPostDate,
    rus.LastEditDate,
    rus.TotalEdits,
    rus.UserRanking
FROM RankedUserStatistics rus
WHERE rus.TotalPosts > 5 AND rus.TotalBadges > 0
ORDER BY rus.UserRanking
LIMIT 10;
