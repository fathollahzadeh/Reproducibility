
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        CASE 
            WHEN p.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') THEN 'Old Post'
            ELSE 'Recent Post'
        END AS PostAge
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    CASE 
        WHEN ub.BadgeCount IS NOT NULL THEN CONCAT('User has ', ub.BadgeCount, ' badges (', ub.GoldBadges, ' Gold, ', ub.SilverBadges, ' Silver, ', ub.BronzeBadges, ' Bronze)')
        ELSE 'User has no badges'
    END AS BadgeStatus,
    COALESCE(cp.CloseCount, 0) AS ClosedPostCount,
    cp.CloseReasons,
    rp.PostAge
FROM RankedPosts rp
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.Rank = 1
AND rp.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 10;
