
WITH UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(DISTINCT p.Id) AS PostCount,
           COUNT(DISTINCT c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostScore AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           COALESCE(ph.EditCount, 0) AS EditCount,
           COALESCE(pl.LinkCount, 0) AS LinkCount,
           COALESCE(rc.ClosedCount, 0) AS ClosedCount,
           p.OwnerUserId
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS EditCount
        FROM PostHistory
        WHERE PostHistoryTypeId IN (4, 5, 6)
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS LinkCount
        FROM PostLinks
        GROUP BY PostId
    ) pl ON p.Id = pl.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS ClosedCount
        FROM PostHistory
        WHERE PostHistoryTypeId IN (10, 11)
        GROUP BY PostId
    ) rc ON p.Id = rc.PostId
)
SELECT us.DisplayName,
       us.Reputation,
       us.PostCount,
       us.CommentCount,
       us.UpVotes,
       us.DownVotes,
       us.GoldBadges,
       us.SilverBadges,
       us.BronzeBadges,
       ps.PostId,
       ps.Title,
       ps.CreationDate,
       ps.Score,
       ps.EditCount,
       ps.LinkCount,
       ps.ClosedCount
FROM UserStats us
JOIN PostScore ps ON us.UserId = ps.OwnerUserId
WHERE us.Reputation > 1000
ORDER BY us.Reputation DESC, ps.Score DESC
LIMIT 50;
