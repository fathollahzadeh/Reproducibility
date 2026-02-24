
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS BodyContent,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.ViewCount > 100
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.PostId
), ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.BodyContent,
    rp.OwnerDisplayName,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.BadgeNames, '-') AS Badges,
    COALESCE(phc.EditCount, 0) AS TotalEdits,
    cp.LastClosedDate,
    CASE 
        WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN rp.OwnerPostRank = 1 THEN 'Most Recent Post by User'
        WHEN rp.OwnerPostRank > 1 THEN 'Older Post by User'
        ELSE 'No Posts'
    END AS UserPostRankStatus
FROM RankedPosts rp
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN PostHistoryCounts phc ON rp.PostId = phc.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
