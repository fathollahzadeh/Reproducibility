WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(rp.BadgeCount, 0) AS BadgeCount,
        COALESCE(cl.ClosedDate, NULL) AS LastClosedDate,
        COALESCE(cl.CloseReason, 'Not Closed') AS LastCloseReason
    FROM 
        Posts p
    LEFT JOIN 
        UserBadges rp ON p.OwnerUserId = rp.UserId
    LEFT JOIN 
        ClosedQuestions cl ON p.Id = cl.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    rp.Id,
    rp.Title,
    rp.ViewCount,
    rp.BadgeCount,
    rp.LastClosedDate,
    rp.LastCloseReason,
    CASE 
        WHEN rp.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN rp.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RecentPosts rp
WHERE 
    rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    rp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;