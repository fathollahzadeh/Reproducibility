WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 END) AS RecentPostCount
    FROM Posts p
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AvgScore, 0) AS AvgScore,
        COALESCE(ap.RecentPostCount, 0) AS RecentPostCount
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN ActiveUserPosts ap ON u.Id = ap.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    AvgScore,
    RecentPostCount
FROM UserPerformance
ORDER BY AvgScore DESC, BadgeCount DESC, TotalViews DESC
LIMIT 100;