
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 10 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount
), 
TagStatistics AS (
    SELECT 
        p.Id AS PostId,
        TRIM(BOTH '<>' FROM UNNEST(string_to_array(p.Tags, '><'))) AS Tag, 
        COUNT(*) AS TagUsageCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, Tag
),
TopTags AS (
    SELECT 
        Tag,
        SUM(TagUsageCount) AS TotalUsage
    FROM 
        TagStatistics
    GROUP BY 
        Tag
    ORDER BY 
        TotalUsage DESC
    LIMIT 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    tt.Tag AS TopTag,
    tt.TotalUsage AS TagUsageCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON fp.Tags LIKE '%' || tt.Tag || '%'
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 100;
