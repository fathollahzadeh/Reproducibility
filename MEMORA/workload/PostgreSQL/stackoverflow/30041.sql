WITH RecursiveTopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, 
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation > 1000
),
PostStatistics AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.PostTypeId, 
           COUNT(v.Id) AS VoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
           MAX(p.CreationDate) AS LastActivityDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
),
UserBadges AS (
    SELECT b.UserId, 
           STRING_AGG(b.Name, ', ') AS BadgesList,
           COUNT(b.Id) AS TotalBadges
    FROM Badges b
    GROUP BY b.UserId
),
ClosedPosts AS (
    SELECT ph.PostId, COUNT(*) AS ClosureCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    tu.DisplayName AS TopUser,
    ts.PostId,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = ts.PostId) AS CommentCount,
    ts.VoteCount,
    ts.UpvoteCount,
    ts.DownvoteCount,
    COALESCE(b.BadgesList, 'No Badges') AS Badges,
    COALESCE(cp.ClosureCount, 0) AS ClosureCount
FROM RecursiveTopUsers tu
INNER JOIN PostStatistics ts ON tu.Id = ts.OwnerUserId
LEFT JOIN UserBadges b ON tu.Id = b.UserId
LEFT JOIN ClosedPosts cp ON ts.PostId = cp.PostId
WHERE ts.PostTypeId = 1
AND ts.LastActivityDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
ORDER BY ts.VoteCount DESC, tu.Reputation DESC
LIMIT 10;