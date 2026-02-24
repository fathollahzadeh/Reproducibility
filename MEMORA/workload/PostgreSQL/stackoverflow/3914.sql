WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT OwnerUserId, COUNT(*) AS PostCount, SUM(ViewCount) AS TotalViews, 
           AVG(Score) AS AverageScore
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY OwnerUserId
),
TopUsers AS (
    SELECT ur.DisplayName, ur.Reputation, ps.PostCount, ps.TotalViews, ps.AverageScore
    FROM UserReputation ur
    JOIN PostStats ps ON ur.Id = ps.OwnerUserId
    WHERE ur.Reputation > 1000
),
ClosedPosts AS (
    SELECT p.Id AS PostId, p.Title, ph.UserDisplayName, ph.CreationDate AS CloseDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
)
SELECT tu.DisplayName, tu.Reputation, 
       COALESCE(COUNT(cp.PostId), 0) AS ClosedPostCount,
       SUM(CASE WHEN cp.CloseDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentClosedPosts,
       STRING_AGG(DISTINCT cp.Title, ', ') AS ClosedPostTitles
FROM TopUsers tu
LEFT JOIN ClosedPosts cp ON tu.DisplayName = cp.UserDisplayName
GROUP BY tu.DisplayName, tu.Reputation
ORDER BY tu.Reputation DESC
LIMIT 10;