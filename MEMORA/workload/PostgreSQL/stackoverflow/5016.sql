
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        OwnerUserId AS UserId,
        COUNT(*) AS RecentPostActivity,
        MAX(CreationDate) AS LastActivityDate
    FROM Posts
    WHERE CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 MONTH'
    GROUP BY OwnerUserId
),
CombinedData AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.QuestionCount,
        us.AnswerCount,
        us.TotalViews,
        us.TotalScore,
        us.TotalBadges,
        COALESCE(ra.RecentPostActivity, 0) AS RecentPostActivity,
        ra.LastActivityDate
    FROM UserStatistics us
    LEFT JOIN RecentActivity ra ON us.UserId = ra.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    TotalBadges,
    RecentPostActivity,
    LastActivityDate
FROM CombinedData
WHERE TotalPosts > 0
ORDER BY TotalScore DESC, TotalViews DESC
FETCH FIRST 10 ROWS ONLY;
