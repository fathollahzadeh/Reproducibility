WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Community User') AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Author,
        ph.Comment,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        ph.Text AS EditContent
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId 
    WHERE 
        rp.PostRank <= 5
),
AggregatedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Author,
        SUM(CASE WHEN pd.Comment IS NOT NULL THEN 1 ELSE 0 END) AS EditCount,
        AVG(pd.Score) AS AverageScore,
        AVG(pd.ViewCount) AS AverageViewCount
    FROM 
        PostDetails pd
    GROUP BY 
        pd.PostId, pd.Title, pd.Author
)
SELECT 
    ap.PostId,
    ap.Title,
    ap.Author,
    ap.EditCount,
    ap.AverageScore,
    ap.AverageViewCount
FROM 
    AggregatedPosts ap
ORDER BY 
    ap.AverageScore DESC, 
    ap.AverageViewCount DESC;