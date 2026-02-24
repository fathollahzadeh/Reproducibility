
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(REPLACE(REPLACE(Tags, '<', ''), '>', ''), ' ')) AS Tag
    FROM 
        RecentPosts
),
TagAggregation AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 1
),
TopTags AS (
    SELECT 
        Tag
    FROM 
        TagAggregation
    ORDER BY 
        UsageCount DESC
    LIMIT 5
),
PostWithTopTags AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerDisplayName, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.CommentCount,
        rp.AnswerCount,
        STRING_AGG(tt.Tag, ', ') AS TopTags
    FROM 
        RecentPosts rp
    JOIN 
        TopTags tt ON tt.Tag = ANY(string_to_array(REPLACE(REPLACE(rp.Tags, '<', ''), '>', ''), ' '))
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.AnswerCount
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.AnswerCount,
    p.TopTags
FROM 
    PostWithTopTags p
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 10;
