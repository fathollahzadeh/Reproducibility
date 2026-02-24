WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
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
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(bp.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(cl.ClosedDate, '1970-01-01') AS ClosedOn,
        RANK() OVER (ORDER BY COALESCE(pc.CommentCount, 0) DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostComments pc ON p.Id = pc.PostId
    LEFT JOIN 
        UserBadges bp ON p.OwnerUserId = bp.UserId
    LEFT JOIN 
        ClosedPosts cl ON p.Id = cl.PostId
    WHERE 
        p.AcceptedAnswerId IS NOT NULL
)
SELECT 
    pm.PostId,
    pm.TotalComments,
    pm.UserBadgeCount,
    pm.ClosedOn,
    CASE 
        WHEN pm.ClosedOn != '1970-01-01' THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN pm.UserBadgeCount > 5 THEN 'Highly Recognized'
        WHEN pm.UserBadgeCount BETWEEN 1 AND 5 THEN 'Moderately Recognized'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    PostMetrics pm
WHERE 
    pm.PostRank <= 10
ORDER BY 
    pm.PostRank ASC;