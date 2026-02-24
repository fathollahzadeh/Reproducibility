WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  
),
PostTags AS (
    SELECT 
        fp.PostId,
        unnest(string_to_array(substring(fp.Tags, 2, length(fp.Tags)-2), '><')) AS Tag
    FROM 
        FilteredPosts fp
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        AVG(fp.ViewCount) AS AvgViews,
        AVG(fp.Score) AS AvgScore
    FROM 
        PostTags pt
    JOIN 
        FilteredPosts fp ON pt.PostId = fp.PostId
    GROUP BY 
        Tag
    ORDER BY 
        PostCount DESC
)
SELECT 
    tu.Tag,
    tu.PostCount,
    tu.AvgViews,
    tu.AvgScore,
    STRING_AGG(fp.Title, ', ' ORDER BY fp.ViewCount DESC) AS RelatedPosts
FROM 
    TagUsage tu
JOIN 
    FilteredPosts fp ON EXISTS (
        SELECT 1 
        FROM PostTags pt 
        WHERE pt.PostId = fp.PostId AND pt.Tag = tu.Tag
    )
GROUP BY 
    tu.Tag, tu.PostCount, tu.AvgViews, tu.AvgScore
ORDER BY 
    tu.PostCount DESC, tu.AvgScore DESC
LIMIT 10;