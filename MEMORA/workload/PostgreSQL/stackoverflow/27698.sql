
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
), 
TagStats AS (
    SELECT 
        LOWER(TRIM(UNNEST(string_to_array(Tags, '>')))) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        TopPosts
    GROUP BY 
        Tag
)
SELECT 
    ts.Tag,
    ts.PostCount,
    COUNT(DISTINCT p.Id) AS PostsInSimilarTags
FROM 
    TagStats ts
JOIN 
    Posts p ON p.Tags LIKE '%' || ts.Tag || '%'
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    ts.Tag, ts.PostCount
ORDER BY 
    ts.PostCount DESC;
