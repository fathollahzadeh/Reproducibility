
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagsStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag, 
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagsStats
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    tt.Tag,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON tt.Tag = ANY(string_to_array(substring(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><'))
WHERE 
    rp.rn <= 5 
ORDER BY 
    tt.TagCount DESC, 
    rp.CreationDate DESC;
