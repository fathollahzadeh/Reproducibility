WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        p.ViewCount,
        p.CommentCount,
        p.FavoriteCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        Posts p
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS TagUsage
    FROM 
        PostWithTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagUsage
    FROM 
        PopularTags
    ORDER BY 
        TagUsage DESC
    LIMIT 10
),
PostsWithTopTags AS (
    SELECT 
        pwt.PostId,
        pwt.Title,
        pwt.CreationDate,
        pwt.Score,
        pwt.TagCount,
        pwt.OwnerDisplayName,
        pwt.AnswerCount,
        pwt.ViewCount,
        pwt.CommentCount,
        pwt.FavoriteCount,
        pwt.PostType,
        tt.Tag
    FROM 
        PostWithTags pwt
    JOIN 
        TopTags tt ON tt.Tag = ANY(string_to_array(substring(pwt.Tags, 2, length(pwt.Tags)-2), '><'))
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.TagCount,
    p.OwnerDisplayName,
    p.AnswerCount,
    p.ViewCount,
    p.CommentCount,
    p.FavoriteCount,
    p.PostType,
    COUNT(DISTINCT p.Tag) as UsedTagCount
FROM 
    PostsWithTopTags p
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.TagCount, p.OwnerDisplayName, p.AnswerCount, p.ViewCount, p.CommentCount, p.FavoriteCount, p.PostType
ORDER BY 
    UsedTagCount DESC, p.Score DESC
LIMIT 100;