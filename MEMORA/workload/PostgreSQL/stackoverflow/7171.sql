WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    rp.OwnerDisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.ViewCount) AS AvgViewCount,
    MAX(rp.ViewCount) AS MaxViewCount,
    AVG(rp.PostRank) AS AvgPostRank
FROM 
    RankedPosts rp
GROUP BY 
    rp.OwnerDisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    TotalScore DESC
LIMIT 10;