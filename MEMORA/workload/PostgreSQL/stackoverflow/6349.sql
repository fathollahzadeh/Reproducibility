WITH UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, COUNT(b.Id) AS BadgeCount 
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS PostCount, 
           SUM(p.Score) AS TotalScore, 
           AVG(p.ViewCount) AS AvgViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ClosedPostReasons AS (
    SELECT ph.UserId, 
           ph.Comment AS CloseReason, 
           COUNT(ph.Id) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.UserId, ph.Comment
),
CombinedStats AS (
    SELECT ur.UserId, 
           ur.Reputation, 
           ur.BadgeCount, 
           ps.PostCount, 
           ps.TotalScore, 
           ps.AvgViews, 
           cpr.CloseCount, 
           cpr.CloseReason
    FROM UserReputation ur
    LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    LEFT JOIN ClosedPostReasons cpr ON ur.UserId = cpr.UserId
)
SELECT UserId, 
       Reputation, 
       BadgeCount, 
       PostCount, 
       TotalScore, 
       AvgViews, 
       CloseCount, 
       CloseReason 
FROM CombinedStats 
WHERE PostCount > 5 AND Reputation > 1000 
ORDER BY TotalScore DESC, Reputation DESC;
