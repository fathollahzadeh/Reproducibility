WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
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
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(STRING_AGG(DISTINCT f.Tags, ','), ',')) AS TagName
    FROM 
        FilteredPosts f
),
TagFrequency AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10 
)
SELECT 
    tf.TagName,
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.Score
FROM 
    TagFrequency tf
JOIN 
    FilteredPosts fp ON tf.TagName = ANY(string_to_array(fp.Tags, ','))
ORDER BY 
    tf.PostCount DESC, 
    fp.Score DESC;