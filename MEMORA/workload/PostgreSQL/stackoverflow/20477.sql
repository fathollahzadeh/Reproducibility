WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
      AND p.ViewCount IS NOT NULL
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastActionDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY ph.PostId
)
SELECT 
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.PopularityRank,
    phd.HistoryTypes,
    phd.HistoryCount,
    phd.LastActionDate
FROM UserBadges ub
LEFT JOIN PopularPosts pp ON pp.PopularityRank <= COALESCE(NULLIF(ub.BadgeCount, 0), 1)
LEFT JOIN PostHistoryDetails phd ON pp.PostId = phd.PostId
WHERE ub.BadgeCount > 0
      AND (pp.ViewCount IS NULL OR pp.ViewCount > 100) 
ORDER BY ub.BadgeCount DESC, pp.ViewCount DESC NULLS LAST;