WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostVoteCounts AS (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT DISTINCT PostId
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
),
RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.OwnerUserId, p.CreationDate,
           pp.UpVotes - pp.DownVotes AS NetScore,
           DENSE_RANK() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    LEFT JOIN PostVoteCounts pp ON p.Id = pp.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
      AND p.PostTypeId IN (1, 2)
      AND p.Id NOT IN (SELECT PostId FROM ClosedPosts)
)
SELECT u.DisplayName, r.RecentRank, COALESCE(ub.GoldBadges, 0) AS GoldBadges,
       COALESCE(ub.SilverBadges, 0) AS SilverBadges,
       COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
       r.Title, r.NetScore
FROM RecentPosts r
JOIN Users u ON r.OwnerUserId = u.Id
LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
WHERE r.NetScore > 0
ORDER BY r.NetScore DESC, r.RecentRank
LIMIT 10;