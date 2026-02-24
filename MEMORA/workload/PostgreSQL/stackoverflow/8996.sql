
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostTypesCount AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostsCount
    FROM Posts
    GROUP BY PostTypeId
),
ClosedPostCount AS (
    SELECT 
        COUNT(*) AS ClosedPosts
    FROM Posts
    WHERE ClosedDate IS NOT NULL
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN PostHistory ph ON u.Id = ph.UserId
    WHERE ph.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY u.Id
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.TotalPosts,
    um.TotalQuestions,
    um.TotalAnswers,
    um.TotalViews,
    um.TotalScore,
    um.TotalBadges,
    pt.PostTypeId,
    pt.PostsCount,
    cpc.ClosedPosts,
    ra.CommentCount,
    ra.HistoryCount
FROM UserMetrics um
CROSS JOIN PostTypesCount pt
CROSS JOIN ClosedPostCount cpc
LEFT JOIN RecentActivity ra ON um.UserId = ra.UserId
ORDER BY um.TotalPosts DESC, um.TotalScore DESC
LIMIT 100;
