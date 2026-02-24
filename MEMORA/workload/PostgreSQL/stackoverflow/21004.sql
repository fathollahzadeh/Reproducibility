WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

ClosedAndEditedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseEvents,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 END) AS EditEvents,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 4, 5)
    GROUP BY 
        ph.PostId
),

UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),

PostsWithTitleReplies AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE((
            SELECT 
                STRING_AGG(c.Text, ' | ') 
            FROM 
                Comments c 
            WHERE 
                c.PostId = p.Id
        ), 'No comments') AS CommentSnippets
    FROM 
        Posts p
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    ca.CloseEvents,
    ca.EditEvents,
    ca.LastEditDate,
    ub.TotalBadges,
    ub.BadgeNames,
    pwtr.CommentSnippets
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedAndEditedPosts ca ON rp.PostId = ca.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = ub.UserId::varchar
LEFT JOIN 
    PostsWithTitleReplies pwtr ON rp.PostId = pwtr.Id
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    COALESCE(ca.CloseEvents, 0) DESC
LIMIT 10;