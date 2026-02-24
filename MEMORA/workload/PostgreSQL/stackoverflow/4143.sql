WITH UserReputation AS (
    SELECT Id, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
           AVG(ViewCount) AS AvgViews
    FROM Posts
    GROUP BY OwnerUserId
),
ClosedPostStats AS (
    SELECT ph.UserId, COUNT(*) AS ClosedPostsCount
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.UserId
),
BadgesSummary AS (
    SELECT UserId, COUNT(*) AS TotalBadges, 
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT u.DisplayName, 
       u.Reputation, 
       COALESCE(ps.TotalPosts, 0) AS TotalPosts, 
       COALESCE(ps.QuestionsCount, 0) AS QuestionsCount, 
       COALESCE(ps.AvgViews, 0) AS AvgViews, 
       COALESCE(cps.ClosedPostsCount, 0) AS ClosedPostsCount,
       COALESCE(bs.TotalBadges, 0) AS TotalBadges,
       COALESCE(bs.GoldBadges, 0) AS GoldBadges,
       COALESCE(bs.SilverBadges, 0) AS SilverBadges,
       COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
       CASE WHEN u.Location IS NULL THEN 'Location Not Provided' ELSE u.Location END AS UserLocation,
       CASE WHEN u.Views > 1000 THEN 'High Viewer' ELSE 'Regular Viewer' END AS ViewerStatus
FROM Users u
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN ClosedPostStats cps ON u.Id = cps.UserId
LEFT JOIN BadgesSummary bs ON u.Id = bs.UserId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY u.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;