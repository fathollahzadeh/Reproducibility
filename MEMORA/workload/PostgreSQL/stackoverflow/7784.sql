WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    WHERE 
        rp.Rank <= 10
    GROUP BY 
        pt.Name
),
EnhancedPostHistory AS (
    SELECT 
        ph.PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS HistoryDate,
        p.OwnerDisplayName,
        p.Score,
        ph.Comment,
        ph.Text AS NewValue,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)
SELECT 
    tp.PostType,
    tp.PostCount,
    tp.AvgScore,
    tp.AvgViewCount,
    ep.PostId,
    ep.Title,
    ep.CreationDate,
    ep.HistoryDate,
    ep.OwnerDisplayName,
    ep.Score,
    ep.Comment,
    ep.NewValue
FROM 
    TopPostStats tp
JOIN 
    EnhancedPostHistory ep ON tp.PostCount > 0
ORDER BY 
    tp.PostType, ep.HistoryDate DESC;