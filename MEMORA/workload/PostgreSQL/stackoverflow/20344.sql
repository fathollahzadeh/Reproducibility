
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        rp.CommentCount,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Average Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rn = 1
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.OwnerDisplayName,
    pm.CommentCount,
    pm.ScoreCategory,
    COALESCE(cpr.CloseReasons, 'No closure reason') AS CloseReasons,
    CASE 
        WHEN pm.ViewCount = 0 THEN 'No Views'
        WHEN pm.ViewCount IS NULL THEN 'Unknown Views'
        ELSE 'Viewed'
    END AS ViewStatus
FROM 
    PostMetrics pm
LEFT JOIN 
    ClosedPostReasons cpr ON pm.PostId = cpr.PostId
WHERE 
    pm.CommentCount > 1
ORDER BY 
    pm.Score DESC,
    pm.CreationDate ASC
FETCH FIRST 50 ROWS ONLY;
