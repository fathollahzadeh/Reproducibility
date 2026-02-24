WITH UserBadgeCounts AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT OwnerUserId,
           COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
           SUM(COALESCE(ViewCount, 0)) AS TotalViews,
           AVG(COALESCE(Score, 0)) AS AverageScore
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY OwnerUserId
),
ClosedPosts AS (
    SELECT p.OwnerUserId, 
           COUNT(*) AS ClosedPostCount,
           MAX(p.ClosedDate) AS LastClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId 
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY p.OwnerUserId
)
SELECT u.DisplayName,
       COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
       COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
       COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
       COALESCE(ps.QuestionCount, 0) AS QuestionCount,
       COALESCE(ps.TotalViews, 0) AS TotalViews,
       COALESCE(ps.AverageScore, 0) AS AverageScore,
       COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount,
       CASE 
           WHEN cp.LastClosedDate IS NOT NULL THEN 'Yes' 
           ELSE 'No' 
       END AS HasClosedPosts
FROM Users u
LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON u.Id = cp.OwnerUserId
WHERE (ubc.GoldBadges IS NOT NULL OR ps.QuestionCount IS NOT NULL OR cp.ClosedPostCount > 0)
ORDER BY u.Reputation DESC
LIMIT 100;