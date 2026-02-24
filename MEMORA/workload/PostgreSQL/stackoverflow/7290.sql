
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(p.Tags, '>'))
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    pts.Tag,
    ph.LastEditDate,
    ph.CloseReopenCount
FROM 
    RankedPosts rp
JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
JOIN 
    PopularTags pts ON pts.Tag = ANY(string_to_array(rp.Tags, '>'))
WHERE 
    rp.RankByViews <= 10
ORDER BY 
    rp.ViewCount DESC, ph.LastEditDate DESC;
