
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserID,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ub.BadgeCount,
    ub.BadgeNames,
    phi.LastClosedDate,
    phi.LastReopenedDate,
    COALESCE(DATE_PART('day', CURRENT_DATE - phi.LastClosedDate), 0) AS DaysSinceClosed,
    COALESCE(DATE_PART('day', CURRENT_DATE - phi.LastReopenedDate), 0) AS DaysSinceReopened,
    CASE 
        WHEN phi.LastClosedDate IS NOT NULL AND phi.LastReopenedDate IS NULL THEN 'Closed'
        WHEN phi.LastClosedDate IS NULL AND phi.LastReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserID
LEFT JOIN 
    PostHistoryInfo phi ON rp.PostID = phi.PostId
WHERE 
    rp.Rank = 1  
ORDER BY 
    rp.Score DESC, ub.BadgeCount DESC;
