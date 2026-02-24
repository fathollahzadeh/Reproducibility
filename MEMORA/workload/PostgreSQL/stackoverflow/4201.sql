WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(au.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users au ON p.OwnerUserId = au.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.rn = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)

SELECT 
    pm.OwnerDisplayName,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.BadgeCount,
    CASE 
        WHEN c.CreationDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostMetrics pm
LEFT JOIN 
    ClosedPosts c ON pm.PostId = c.PostId
WHERE 
    pm.ViewCount > 50
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 100;