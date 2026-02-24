WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        RANK() OVER (PARTITION BY pt.Id ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND 
        p.Score > 0
),
RelevantTags AS (
    SELECT 
        PostId,
        UNNEST(string_to_array(Substring(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag
    FROM 
        RankedPosts
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        RelevantTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5
),
TopPosts AS (
    SELECT 
        r.* 
    FROM 
        RankedPosts r
    JOIN 
        TagCounts tc ON r.Tags LIKE CONCAT('%<', tc.Tag, '>%')
    WHERE 
        r.RankScore <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.PostTypeName,
    STRING_AGG(DISTINCT tc.Tag, ', ') AS RelatedTags
FROM 
    TopPosts tp
JOIN 
    RelevantTags rt ON tp.PostId = rt.PostId
JOIN 
    TagCounts tc ON rt.Tag = tc.Tag
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.PostTypeName
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;