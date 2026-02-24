
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT TRIM(tag)) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),

TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        TagCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
),

TagSummary AS (
    SELECT
        TRIM(tag) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        UNNEST(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS tag
    GROUP BY 
        TRIM(tag)
)

SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    tq.OwnerDisplayName,
    tq.TagCount,
    ts.TagName,
    ts.PostCount
FROM 
    TopQuestions tq
LEFT JOIN 
    TagSummary ts ON ts.PostCount > 5  
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
