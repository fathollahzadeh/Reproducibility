
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY Tag ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p,
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '>')) AS Tag
    WHERE 
        p.PostTypeId = 1 
), 
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        u.DisplayName AS OwnerName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5 
), 
PostStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViews,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        TopRankedPosts tp
    CROSS JOIN 
        UNNEST(string_to_array(tp.Tags, '>')) AS Tag
    GROUP BY 
        Tag
)

SELECT 
    ps.Tag,
    ps.TotalPosts,
    ps.AvgViews,
    ps.PositiveScoreCount,
    STRING_AGG(tp.Title, '; ') AS TopPostTitles
FROM 
    PostStatistics ps
JOIN 
    TopRankedPosts tp ON tp.Tags LIKE '%' || ps.Tag || '%'
GROUP BY 
    ps.Tag, ps.TotalPosts, ps.AvgViews, ps.PositiveScoreCount
ORDER BY 
    ps.TotalPosts DESC, ps.AvgViews DESC;
