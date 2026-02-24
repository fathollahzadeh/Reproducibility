WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
ConsolidatedPostData AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.OwnerDisplayName,
        rp.LinkCount,
        COALESCE(phh.PostHistoryTypeId, 0) AS LastHistoryType
    FROM 
        RankedPosts r
    LEFT JOIN (
        SELECT
            p.Id AS PostId,
            COUNT(pl.Id) AS LinkCount
        FROM 
            Posts p
        JOIN 
            PostLinks pl ON p.Id = pl.PostId
        GROUP BY 
            p.Id
    ) rp ON r.PostId = rp.PostId
    LEFT JOIN 
        RecentPostHistory phh ON r.PostId = phh.PostId AND phh.HistoryRank = 1
)
SELECT 
    cp.Title,
    cp.OwnerDisplayName,
    cp.CreationDate,
    cp.Score,
    cp.ViewCount,
    cp.LinkCount,
    CASE 
        WHEN cp.LastHistoryType = 10 THEN 'Closed'
        WHEN cp.LastHistoryType = 11 THEN 'Reopened'
        WHEN cp.LastHistoryType = 12 THEN 'Deleted'
        ELSE 'Active'
    END AS Status
FROM 
    ConsolidatedPostData cp
WHERE 
    cp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
ORDER BY 
    cp.Score DESC, cp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;