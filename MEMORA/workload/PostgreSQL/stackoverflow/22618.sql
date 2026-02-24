
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '5 years'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(phd.EditCount, 0) AS EditCount,
    COALESCE(phd.CloseReopenCount, 0) AS CloseReopenCount,
    CASE 
        WHEN rp.PopularityRank <= 10 THEN 'Hot' 
        WHEN rp.PopularityRank <= 50 THEN 'Trending' 
        ELSE 'Average' 
    END AS PopularityStatus,
    CASE 
        WHEN phd.FirstEditDate IS NOT NULL 
         THEN EXTRACT(EPOCH FROM (phd.LastEditDate - phd.FirstEditDate)) / 3600
         ELSE NULL 
    END AS HoursBetweenFirstAndLastEdit
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate ASC;
