WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        rp.RankByViews,
        rp.RankByScore
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.RankByViews <= 5 OR rp.RankByScore <= 5
),
PostStats AS (
    SELECT 
        tp.OwnerDisplayName,
        COUNT(tp.PostId) AS TotalPosts,
        SUM(tp.ViewCount) AS TotalViews,
        SUM(tp.Score) AS TotalScore
    FROM 
        TopPosts tp
    GROUP BY 
        tp.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalScore,
    CASE 
        WHEN ps.TotalScore > 100 THEN 'High Scorer'
        WHEN ps.TotalScore BETWEEN 50 AND 100 THEN 'Medium Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    PostStats ps
ORDER BY 
    ps.TotalScore DESC;