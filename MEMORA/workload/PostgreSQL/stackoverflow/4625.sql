WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        COALESCE(AVG(p.Score), 0) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
FinalStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AvgScore, 0) AS AvgScore
    FROM Users u
    LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId, 
    DisplayName, 
    BadgeCount,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    AvgScore,
    CASE 
        WHEN TotalPosts > 50 THEN 'Active Contributor'
        WHEN TotalPosts BETWEEN 20 AND 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM FinalStats
WHERE TotalViews > 1000
ORDER BY TotalPosts DESC, AvgScore DESC
LIMIT 10;