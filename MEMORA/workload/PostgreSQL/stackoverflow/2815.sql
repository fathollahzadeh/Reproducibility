WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(ph.EditCount, 0) AS EditCount,
    ph.LastEditDate,
    rp.CreationDate,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Most Recent Post'
        ELSE 'Older Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.Id = pc.PostId
LEFT JOIN 
    PostHistoryAggregates ph ON rp.Id = ph.PostId
WHERE 
    rp.UserPostRank <= 5
    OR (COALESCE(pc.CommentCount, 0) > 5 AND rp.Score > 20)
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC;