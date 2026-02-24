
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
        AND rp.CommentCount IS NOT NULL
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, 
        ph.PostHistoryTypeId
),
JoinCounts AS (
    SELECT 
        tp.PostId,
        SUM(CASE WHEN phs.ChangeCount > 0 THEN phs.ChangeCount ELSE 0 END) AS TotalChanges
    FROM 
        TopQuestions tp
    LEFT JOIN 
        PostHistorySummary phs ON tp.PostId = phs.PostId
    GROUP BY 
        tp.PostId
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    COALESCE(jc.TotalChanges, 0) AS TotalChanges,
    CASE 
        WHEN jc.TotalChanges IS NOT NULL THEN 
            CASE 
                WHEN jc.TotalChanges > 5 THEN 'Highly Active'
                WHEN jc.TotalChanges BETWEEN 1 AND 5 THEN 'Moderately Active'
                ELSE 'Inactive' 
            END
        ELSE 'No Changes'
    END AS ActivityLevel,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p2 ON p2.Tags LIKE '%' || t.TagName || '%' 
     WHERE p2.Id = tp.PostId) AS Tags
FROM 
    TopQuestions tp
LEFT JOIN 
    JoinCounts jc ON tp.PostId = jc.PostId
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.Comment IS NULL 
    OR ph.Comment NOT LIKE '%duplicate%'
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
