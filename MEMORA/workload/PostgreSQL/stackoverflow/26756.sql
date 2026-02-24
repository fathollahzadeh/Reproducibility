
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
),
TaggedQuestions AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        OwnerReputation,
        CreationDate,
        LastActivityDate,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1  
        AND Tags IS NOT NULL 
),
MostCommonTags AS (
    SELECT 
        TRIM(unnest(string_to_array(Tags, ','))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TaggedQuestions
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10 
)
SELECT 
    tq.OwnerDisplayName,
    tq.Title,
    tq.Body,
    tq.Tags,
    tq.ViewCount,
    tq.Score,
    ct.TagName,
    ct.TagCount
FROM 
    TaggedQuestions tq
JOIN 
    MostCommonTags ct ON POSITION(ct.TagName IN tq.Tags) > 0  
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
