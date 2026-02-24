
WITH RankedPosts AS (
    SELECT p.Id AS PostID, p.OwnerUserId, p.Title, p.Score, 
           ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT u.Id AS UserID, u.DisplayName, u.Reputation, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
           COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT ph.PostId, COUNT(*) AS EditCount, 
           MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT r.Title, r.Score, u.DisplayName, u.Reputation, 
       us.Upvotes, us.Downvotes, us.BadgeCount, phs.EditCount, phs.LastEditDate
FROM RankedPosts r
JOIN Users u ON r.OwnerUserId = u.Id
JOIN UserStats us ON u.Id = us.UserID
JOIN PostHistorySummary phs ON r.PostID = phs.PostId
WHERE r.rn = 1
ORDER BY r.Score DESC, u.Reputation DESC
LIMIT 20;
