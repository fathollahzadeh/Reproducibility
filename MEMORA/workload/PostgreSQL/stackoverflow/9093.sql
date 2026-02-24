WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)

SELECT 
    rp.OwnerDisplayName,
    COUNT(CASE WHEN rp.RankByScore <= 5 THEN 1 END) AS TopScorePosts,
    COUNT(CASE WHEN rp.RankByViews <= 5 THEN 1 END) AS TopViewPosts,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews
FROM 
    RankedPosts rp
GROUP BY 
    rp.OwnerDisplayName
HAVING 
    SUM(rp.Score) > 10
ORDER BY 
    TotalScore DESC, TotalViews DESC;