WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

FilteredTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        p.Title,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.PostId, p.Title
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ft.TagName,
    CASE 
        WHEN ps.HistoryCount > 0 THEN 'Has Post History'
        ELSE 'No Post History'
    END AS HistoryStatus,
    ps.LastUpdate
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredTags ft ON rp.Title LIKE '%' || ft.TagName || '%'
LEFT JOIN 
    PostHistorySummary ps ON rp.PostId = ps.PostId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;