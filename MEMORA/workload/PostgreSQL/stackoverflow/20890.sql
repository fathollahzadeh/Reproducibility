
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostInteractions AS (
    SELECT 
        p.Id AS postId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    pi.CommentCount,
    pi.TotalBounty,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    phs.CloseCount,
    phs.ReopenCount,
    CASE 
        WHEN phs.CloseCount > 0 AND phs.ReopenCount = 0 THEN 'Closed Only'
        WHEN phs.ReopenCount > 0 AND phs.CloseCount = 0 THEN 'Reopened Only'
        ELSE 'Mixed'
    END AS ClosureStatus,
    CASE 
        WHEN ub.BadgeCount > 10 THEN 'Highly Recognized'
        WHEN ub.BadgeCount BETWEEN 5 AND 10 THEN 'Moderately Recognized'
        ELSE 'New User'
    END AS UserRecognition
FROM 
    RankedPosts rp
LEFT JOIN 
    PostInteractions pi ON rp.PostId = pi.postId
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
LEFT JOIN 
    PostHistoryStats phs ON rp.PostId = phs.PostId
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.ViewCount DESC, pi.CommentCount DESC, ub.BadgeCount DESC;