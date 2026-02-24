WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        TagFrequency,
        ROW_NUMBER() OVER (ORDER BY TagFrequency DESC) AS PopularityRank
    FROM 
        TagCounts
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate,
    rp.OwnerDisplayName,
    pt.Tag AS MostPopularTag
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.PopularityRank = 1
WHERE 
    rp.RankByViews <= 5 
ORDER BY 
    rp.OwnerDisplayName, 
    rp.ViewCount DESC;