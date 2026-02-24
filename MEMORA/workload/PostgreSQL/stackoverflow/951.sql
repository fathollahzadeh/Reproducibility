
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, 
        p.Title, 
        p.OwnerDisplayName, 
        p.CreationDate, 
        p.ViewCount
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenedCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.ViewCount,
    rp.RankByScore,
    COALESCE(pHD.CloseReopenedCount, 0) AS CloseReopenedCount,
    pHD.FirstEditDate,
    pHD.LastEditDate,
    CASE 
        WHEN rp.RankByScore <= 3 THEN 'Top Post'
        WHEN rp.RankByScore <= 10 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PopularityStatus
FROM RankedPosts rp
FULL OUTER JOIN PostHistoryDetail pHD ON rp.PostId = pHD.PostId
WHERE rp.RankByScore IS NOT NULL OR pHD.PostId IS NOT NULL
ORDER BY 
    rp.RankByScore ASC NULLS LAST,
    pHD.FirstEditDate DESC;
