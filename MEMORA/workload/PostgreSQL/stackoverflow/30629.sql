WITH RECURSIVE UserReputation AS (
    SELECT Id, DisplayName, Reputation, CreationDate, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
    WHERE Reputation IS NOT NULL
), RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.OwnerUserId, p.CreationDate, 
           p.ViewCount, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
), PostVoteSummary AS (
    SELECT v.PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(v.Id) AS TotalVotes
    FROM Votes v
    GROUP BY v.PostId
), ClosedPosts AS (
    SELECT p.Id AS ClosedPostId, p.Title, p.ClosedDate, 
           ph.UserId AS ClosedBy
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
), UserBadges AS (
    SELECT b.UserId, COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)

SELECT ur.DisplayName,
       ur.Reputation,
       COALESCE(up.BadgeCount, 0) AS UserBadges,
       rp.Title AS RecentPostTitle,
       rp.ViewCount,
       ps.UpVotes,
       ps.DownVotes,
       ps.TotalVotes,
       cp.ClosedPostId,
       cp.ClosedBy AS ClosedByUser
FROM UserReputation ur
LEFT JOIN UserBadges up ON ur.Id = up.UserId
LEFT JOIN RecentPosts rp ON ur.Id = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN PostVoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN ClosedPosts cp ON ur.Id = cp.ClosedBy
WHERE ur.Reputation > (SELECT AVG(Reputation) FROM Users)
  AND (cp.ClosedPostId IS NULL OR cp.Title LIKE '%help%')
ORDER BY ur.Reputation DESC, rp.ViewCount DESC NULLS LAST
LIMIT 10;