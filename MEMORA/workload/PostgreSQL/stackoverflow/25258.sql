
WITH RecentPosts AS (
    SELECT 
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '>')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '>'))
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 1 
),
PopularPosts AS (
    SELECT 
        rp.*,
        tt.Tag,
        tt.TagCount
    FROM 
        RecentPosts rp
    JOIN 
        TopTags tt ON rp.Tags LIKE '%' || tt.Tag || '%'
    ORDER BY 
        rp.ViewCount DESC, 
        rp.Score DESC
    LIMIT 10
)
SELECT 
    pp.Title,
    pp.OwnerDisplayName,
    pp.ViewCount,
    pp.Score,
    pp.CreationDate,
    pp.Tag,
    pp.TagCount
FROM 
    PopularPosts pp
ORDER BY 
    pp.CreationDate DESC;
