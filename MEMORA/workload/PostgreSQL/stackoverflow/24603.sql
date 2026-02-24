WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(b.Name, 'No Badge') AS UserBadge,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1
    WHERE 
        p.PostTypeId = 1 
        AND u.Reputation > 1000
), 
CommentsAgg AS (
    SELECT 
        cm.PostId, 
        COUNT(cm.Id) AS CommentCount,
        STRING_AGG(cm.Text, ' | ') AS CommentTexts
    FROM 
        Comments cm
    GROUP BY 
        cm.PostId
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId = 10) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
), 
RelevantPostInfo AS (
    SELECT 
        rp.*,
        ca.CommentCount,
        ca.CommentTexts,
        cp.ClosedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentsAgg ca ON rp.PostId = ca.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    rpi.PostId,
    rpi.Title,
    rpi.CreationDate,
    rpi.Score,
    rpi.ViewCount,
    rpi.UserBadge,
    rpi.CommentCount,
    rpi.CommentTexts,
    rpi.ClosedDate,
    CASE 
        WHEN rpi.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rpi.ClosedDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Long Closed'
        ELSE 'Recently Closed'
    END AS ClosureDuration,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rpi.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rpi.PostId AND v.VoteTypeId = 3) AS DownvoteCount
FROM 
    RelevantPostInfo rpi
WHERE 
    rpi.Score > 10
ORDER BY 
    rpi.Score DESC, rpi.ViewCount DESC
LIMIT 50;