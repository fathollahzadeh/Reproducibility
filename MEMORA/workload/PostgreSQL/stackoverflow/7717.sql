
WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
),
PopularPosts AS (
    SELECT p.Id, p.Title, p.Score, COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 AND p.Score >= 10
    GROUP BY p.Id, p.Title, p.Score
),
PostHistorySummary AS (
    SELECT ph.PostId, 
           ph.PostHistoryTypeId, 
           COUNT(*) AS HistoryCount
    FROM PostHistory ph
    WHERE ph.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, ub.TotalBadges
    FROM Users u
    JOIN UserBadges ub ON u.Id = ub.UserId
    ORDER BY u.Reputation DESC, ub.TotalBadges DESC
    LIMIT 10
)
SELECT pu.DisplayName AS TopUser, 
       pp.Title AS PopularPostTitle, 
       pp.Score AS PopularPostScore, 
       phs.PostHistoryTypeId AS HistoryType, 
       phs.HistoryCount AS HistoryTypeCount
FROM TopUsers pu
JOIN PopularPosts pp ON pp.CommentCount > 5
JOIN PostHistorySummary phs ON pp.Id = phs.PostId
WHERE pu.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = pp.Id)
ORDER BY pu.Reputation DESC, pp.Score DESC;
