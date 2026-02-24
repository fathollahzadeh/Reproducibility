WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
),

AggregatedTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId = 1
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        AggregatedTags
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.Tags LIKE '%<' || tt.TagName || '>%'
WHERE 
    rp.ViewRank <= 5  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;