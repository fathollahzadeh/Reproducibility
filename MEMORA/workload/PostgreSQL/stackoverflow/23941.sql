WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rb.BadgeCount,
    rb.BadgeNames,
    phs.EditCount,
    phs.LastClosedDate,
    phs.LastReopenedDate,
    CASE 
        WHEN phs.LastClosedDate IS NOT NULL AND phs.LastReopenedDate IS NULL 
        THEN 'Closed'
        WHEN phs.LastReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(NULLIF(rp.Title, ''), 'Untitled Post') AS SafeTitle
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges rb ON rb.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = rp.PostId
WHERE 
    (phs.LastClosedDate IS NULL OR phs.LastClosedDate > '2023-01-01')
    AND rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount ASC;