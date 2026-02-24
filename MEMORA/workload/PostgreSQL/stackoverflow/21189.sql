WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        CASE 
            WHEN u.Views IS NULL THEN 'Unknown'
            WHEN u.Views < 100 THEN 'Low Engagement'
            WHEN u.Views BETWEEN 100 AND 1000 THEN 'Moderate Engagement'
            ELSE 'High Engagement'
        END AS EngagementLevel
    FROM 
        Users u
    WHERE 
        u.Reputation > 100
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.CreationDate,
    rp.LastActivityDate,
    fu.DisplayName AS OwnerName,
    fu.EngagementLevel,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    COALESCE(rc.LastCommentDate, NULL) AS LastCommentDate,
    COALESCE(phd.EditCount, 0) AS EditHistoryCount,
    COALESCE(phd.LastEditDate, NULL) AS LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredUsers fu ON rp.OwnerUserId = fu.UserId
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    PostHistoryData phd ON rp.PostId = phd.PostId
WHERE 
    rp.rn = 1 
    AND (fu.Reputation >= 500 OR rp.Score > 10)
ORDER BY 
    rp.Score DESC NULLS LAST, 
    rp.CreationDate DESC;