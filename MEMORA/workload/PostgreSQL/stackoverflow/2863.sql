
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
VotesSummary AS (
    SELECT v.PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Votes v
    GROUP BY v.PostId
),
ClosedPosts AS (
    SELECT h.PostId, 
           MAX(h.CreationDate) AS LastClosedDate,
           STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory h
    JOIN CloseReasonTypes cr ON CAST(h.Comment AS INT) = cr.Id
    WHERE h.PostHistoryTypeId = 10 
    GROUP BY h.PostId
)
SELECT rp.Title, rp.CreationDate, u.DisplayName, u.Reputation, us.BadgeCount,
       COALESCE(vs.UpVotesCount, 0) AS UpVotes, COALESCE(vs.DownVotesCount, 0) AS DownVotes,
       cp.LastClosedDate, cp.CloseReasons
FROM RankedPosts rp
JOIN Users u ON u.Id = rp.OwnerUserId
JOIN UserReputation us ON us.UserId = u.Id
LEFT JOIN VotesSummary vs ON vs.PostId = rp.Id
LEFT JOIN ClosedPosts cp ON cp.PostId = rp.Id
WHERE rp.rn = 1
  AND (us.Reputation > 1000 OR cp.LastClosedDate IS NOT NULL)
ORDER BY rp.CreationDate DESC
LIMIT 10;
