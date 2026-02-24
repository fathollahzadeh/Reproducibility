
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LatestEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CreationDate,
        re.EditCount,
        re.LatestEditDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits re ON rp.PostId = re.PostId
    WHERE 
        rp.RankByViews <= 10 
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.CreationDate,
    COALESCE(ps.EditCount, 0) AS EditCount,
    ps.LatestEditDate,
    CASE 
        WHEN ps.EditCount IS NOT NULL THEN 
            CASE 
                WHEN DATE_PART('day', CURRENT_DATE - ps.LatestEditDate) <= 30 THEN 'Recently Edited'
                ELSE 'Edited More Than 30 Days Ago'
            END
        ELSE 'Never Edited'
    END AS EditStatus
FROM 
    PostStatistics ps
ORDER BY 
    ps.ViewCount DESC;
