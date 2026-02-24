
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId AS EditorUserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6, 10)
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    pp.Title AS RecentPostTitle,
    pp.CreationDate AS RecentPostDate,
    pp.UpVotes,
    pp.DownVotes,
    pp.CommentCount,
    phd.PostHistoryTypeId,
    phd.CreationDate AS EditDate,
    phd.EditorUserId,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount
FROM Users u
JOIN RankedPosts pp ON u.Id = pp.OwnerUserId AND pp.RecentPostRank = 1
LEFT JOIN PostHistoryDetails phd ON pp.PostId = phd.PostId AND phd.EditRank = 1
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE (u.Reputation IS NOT NULL OR u.Location IS NOT NULL)
  AND NOT EXISTS (
      SELECT 1 
      FROM Comments c 
      WHERE c.UserId = u.Id AND c.CreationDate < pp.CreationDate
  )
ORDER BY u.Reputation DESC, pp.UpVotes DESC
LIMIT 50;
