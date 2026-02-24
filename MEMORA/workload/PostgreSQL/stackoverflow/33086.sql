WITH RECURSIVE UserBadges AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           b.Name AS BadgeName, 
           b.Class,
           b.Date,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM Users u
    JOIN Badges b ON u.Id = b.UserId
),
PostStatistics AS (
    SELECT p.OwnerUserId, 
           COUNT(*) AS TotalPosts,
           AVG(p.Score) AS AverageScore,
           SUM(p.ViewCount) AS TotalViews,
           COUNT(c.Id) AS TotalComments,
           COALESCE(MAX(v.CreationDate), '1900-01-01') AS LastVoteDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.OwnerUserId
),
ClosedPosts AS (
    SELECT p.OwnerUserId, 
           COUNT(*) AS ClosedPostCount,
           AVG(p.Score) AS AvgClosedPostScore
    FROM Posts p
    WHERE p.ClosedDate IS NOT NULL
    GROUP BY p.OwnerUserId
),
MostActiveUsers AS (
    SELECT ps.OwnerUserId,
           us.DisplayName,
           ps.TotalPosts,
           ps.AverageScore,
           ps.TotalViews,
           ps.TotalComments,
           COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount,
           COALESCE(cp.AvgClosedPostScore, 0) AS AvgClosedPostScore,
           RANK() OVER (ORDER BY ps.TotalPosts DESC) AS OverallRank
    FROM PostStatistics ps
    LEFT JOIN ClosedPosts cp ON ps.OwnerUserId = cp.OwnerUserId
    JOIN Users us ON ps.OwnerUserId = us.Id
)
SELECT mu.DisplayName,
       mu.TotalPosts,
       mu.AverageScore,
       mu.TotalViews,
       mu.TotalComments,
       mu.ClosedPostCount,
       mu.AvgClosedPostScore,
       COUNT(DISTINCT ub.BadgeName) AS UniqueBadgeCount
FROM MostActiveUsers mu
LEFT JOIN UserBadges ub ON mu.OwnerUserId = ub.UserId AND ub.BadgeRank = 1
WHERE mu.TotalPosts > 10
GROUP BY mu.DisplayName, mu.TotalPosts, mu.AverageScore, mu.TotalViews, mu.TotalComments, mu.ClosedPostCount, mu.AvgClosedPostScore
ORDER BY mu.TotalPosts DESC, UniqueBadgeCount DESC
FETCH FIRST 10 ROWS ONLY;

