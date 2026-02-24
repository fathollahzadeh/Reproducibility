WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
AggregatedData AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore
    FROM 
        TopPosts
)
SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.Score,
    ad.TotalPosts,
    ad.AvgViewCount,
    ad.TotalScore
FROM 
    TopPosts tp
CROSS JOIN 
    AggregatedData ad
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;