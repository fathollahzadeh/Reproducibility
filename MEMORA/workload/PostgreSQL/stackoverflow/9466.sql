WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
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
        COUNT(pt.Id) AS PostCount,
        SUM(pt.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    pt.TagName,
    pt.TotalViews AS TagTotalViews
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Rank <= 5
ORDER BY 
    rp.PostId DESC, pt.TotalViews DESC;