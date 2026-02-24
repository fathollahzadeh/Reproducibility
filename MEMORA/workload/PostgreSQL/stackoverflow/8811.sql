WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),

PopularTags AS (
    SELECT 
        ts.TagName,
        ts.TotalPosts,
        ts.TotalViews,
        ts.AvgScore,
        ROW_NUMBER() OVER (ORDER BY ts.TotalPosts DESC, ts.AvgScore DESC) AS TagRank
    FROM 
        TagStats ts
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    pt.TagName AS PopularTag,
    pt.TotalPosts,
    pt.TotalViews,
    pt.AvgScore
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Rank <= 10 AND pt.TagRank <= 10
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;