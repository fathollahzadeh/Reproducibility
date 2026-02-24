WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseReasonsCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment END) AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)

SELECT 
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    ub.BadgeCount,
    ub.BadgeNames,
    cp.CloseReasonsCount,
    cp.LastClosedDate,
    cp.CloseReason,
    CASE 
        WHEN up.rn = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank
FROM 
    RankedPosts up
LEFT JOIN 
    UserBadges ub ON up.OwnerUserId = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON up.PostId = cp.PostId
WHERE 
    (ub.BadgeCount > 0 OR ub.BadgeCount IS NULL) 
    AND (cp.CloseReasonsCount IS NULL OR cp.CloseReasonsCount > 1) 
ORDER BY 
    up.CreationDate DESC, 
    up.Score DESC
LIMIT 100;