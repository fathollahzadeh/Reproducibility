WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount
    FROM RankedPosts rp
    WHERE rp.Rank <= 3
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
PostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM TopPosts tp
    LEFT JOIN PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    pm.Title,
    pm.OwnerDisplayName,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    CASE 
        WHEN pm.Score > 100 THEN 'High Engagement'
        WHEN pm.Score BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM PostMetrics pm
ORDER BY pm.Score DESC;