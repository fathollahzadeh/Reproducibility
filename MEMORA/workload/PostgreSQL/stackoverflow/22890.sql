WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByPopularity
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
      AND p.Score IS NOT NULL
), CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment END, ', ') AS Reasons
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    COALESCE(crc.CloseReasonCount, 0) AS TotalCloseReasons,
    COALESCE(crc.Reasons, 'No close reasons') AS CloseReasons,
    CASE
        WHEN ubc.GoldBadges > 0 THEN 'Top Contributor'
        WHEN ubc.SilverBadges > 0 OR ubc.BronzeBadges > 0 THEN 'Active Contributor'
        ELSE 'Newcomer'
    END AS UserStatus
FROM UserBadgeCounts ubc
JOIN Users u ON u.Id = ubc.UserId
LEFT JOIN PopularPosts pp ON pp.OwnerUserId = u.Id AND pp.RankByPopularity <= 5
LEFT JOIN CloseReasonCounts crc ON pp.Id = crc.PostId
WHERE u.Reputation >= 100
ORDER BY u.Reputation DESC, pp.Score DESC NULLS LAST;