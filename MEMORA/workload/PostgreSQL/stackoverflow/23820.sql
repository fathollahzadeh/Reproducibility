
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.OwnerUserId,
           COALESCE(p.Score, 0) AS Score,
           p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(p.Score, 0) DESC, p.CreationDate ASC) AS PostRank,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.Score, p.ViewCount, p.CreationDate
),
UserReputation AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation
),
PostHistorySummary AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           COUNT(*) AS HistoryCount,
           STRING_AGG(ph.UserDisplayName, ', ' ORDER BY ph.CreationDate ASC) AS Editors
    FROM PostHistory ph
    WHERE ph.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '2 years'
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
UserStats AS (
    SELECT ur.UserId,
           ur.Reputation,
           ur.BadgeCount,
           ur.UpVotesCount,
           SUM(CASE WHEN rp.PostRank <= 5 THEN 1 ELSE 0 END) AS TopPostsCount,
           COUNT(DISTINCT ph.PostId) AS HistoryEditCount
    FROM UserReputation ur
    LEFT JOIN RankedPosts rp ON ur.UserId = rp.OwnerUserId
    LEFT JOIN PostHistorySummary ph ON rp.PostId = ph.PostId
    GROUP BY ur.UserId, ur.Reputation, ur.BadgeCount, ur.UpVotesCount
)
SELECT us.UserId,
       us.Reputation,
       us.BadgeCount,
       us.UpVotesCount,
       us.TopPostsCount,
       us.HistoryEditCount,
       CASE 
           WHEN us.Reputation > 1000 THEN 'Highly Influential'
           WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Moderately Influential'
           ELSE 'New Contributor'
       END AS ContributorLevel,
       (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = us.UserId AND p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '5 years') AS PostsCreatedLast5Years,
       CASE 
           WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = us.UserId AND b.Class = 1) THEN 'Gold Badge Holder'
           ELSE 'No Gold Badges'
       END AS BadgeStatus
FROM UserStats us
WHERE us.TopPostsCount > 0
ORDER BY us.Reputation DESC, us.BadgeCount DESC, us.UpVotesCount DESC;
