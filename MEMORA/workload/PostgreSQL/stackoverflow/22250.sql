WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p 
    WHERE p.Score IS NOT NULL AND p.ViewCount > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u 
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(pt.Name, ', ') AS PostHistoryTypeNames
    FROM PostHistory ph 
    JOIN PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    GROUP BY ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        phd.EditCount,
        phd.LastEditDate,
        phd.PostHistoryTypeNames,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'High Engagement'
            WHEN rp.ViewCount BETWEEN 500 AND 999 THEN 'Medium Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM RankedPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
    WHERE rp.rn = 1
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Reputation,
    fp.BadgeCount,
    fp.GoldBadges,
    fp.SilverBadges,
    fp.BronzeBadges,
    fp.EditCount,
    fp.LastEditDate,
    fp.PostHistoryTypeNames,
    fp.EngagementLevel
FROM FilteredPosts fp
WHERE 
    (fp.Reputation > 1000 OR fp.BadgeCount > 3)
    AND (fp.EditCount IS NOT NULL AND fp.EditCount > 0)
ORDER BY 
    fp.Score DESC,
    fp.ViewCount DESC
LIMIT 50;