WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 0
        AND p.Score >= (SELECT AVG(Score) FROM Posts WHERE ViewCount > 0)
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        b.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(CASE WHEN c.UserDisplayName IS NOT NULL THEN c.UserDisplayName ELSE 'Unknown User' END, ', ') AS Commenters
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FilteredPostHistory AS (
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
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(pb.BadgeNames, 'No Badges') AS UserBadges,
    COALESCE(fph.LastClosedDate, fph.LastReopenedDate) AS LastStatusChange
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    Users u ON rp.PostId = u.Id 
LEFT JOIN 
    RecentBadges pb ON u.Id = pb.UserId
LEFT JOIN 
    FilteredPostHistory fph ON rp.PostId = fph.PostId
WHERE 
    (rp.ViewCount > 100 OR rp.Score > 10)
    AND (fph.LastClosedDate IS NULL OR fph.LastClosedDate < fph.LastReopenedDate OR fph.LastReopenedDate IS NULL)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;