
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
           COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVoteCount,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
), 
UserReputation AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.Reputation
), 
UserTopPosts AS (
    SELECT r.PostId,
           r.Title,
           r.Score,
           r.OwnerUserId,
           ur.TotalPosts,
           ur.Reputation,
           ur.GoldBadges,
           ur.SilverBadges,
           ur.BronzeBadges,
           RANK() OVER (PARTITION BY ur.UserId ORDER BY r.Score DESC) AS PostRank
    FROM RankedPosts r
    JOIN UserReputation ur ON r.OwnerUserId = ur.UserId
    WHERE r.rn = 1
), 
ClosedPosts AS (
    SELECT ph.PostId,
           COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount,
           MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT utp.PostId,
       utp.Title,
       utp.Score,
       ur.TotalPosts,
       ur.Reputation,
       COALESCE(upv.UpVoteCount, 0) AS UpVoteCount,
       COALESCE(dnv.DownVoteCount, 0) AS DownVoteCount,
       cp.ClosedCount,
       cp.LastClosedDate
FROM UserTopPosts utp
JOIN UserReputation ur ON utp.OwnerUserId = ur.UserId
LEFT JOIN (
    SELECT p.Id AS PostId,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
) upv ON utp.PostId = upv.PostId
LEFT JOIN (
    SELECT p.Id AS PostId,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
) dnv ON utp.PostId = dnv.PostId
LEFT JOIN ClosedPosts cp ON utp.PostId = cp.PostId
WHERE ur.Reputation IS NOT NULL
  AND (cp.ClosedCount > 0 OR cp.LastClosedDate IS NULL)
ORDER BY utp.Score DESC, ur.TotalPosts DESC;
