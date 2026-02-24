
WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostsWithCloseReasons AS (
    SELECT
        ph.PostId,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes ct ON ph.Comment = CAST(ct.Id AS TEXT)
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId
)
SELECT
    up.DisplayName AS UserDisplayName,
    up.Reputation,
    rp.Title,
    rp.Score,
    ub.BadgeCount,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount,
    COALESCE(pc.CloseReasons, 'No close reasons') AS CloseReasons
FROM Users up
JOIN RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN UserBadges ub ON up.Id = ub.UserId
LEFT JOIN PostsWithCloseReasons pc ON rp.Id = pc.PostId
WHERE rp.PostRank = 1
AND up.Reputation > 1000
ORDER BY ub.BadgeCount DESC, rp.Score DESC
LIMIT 10;
