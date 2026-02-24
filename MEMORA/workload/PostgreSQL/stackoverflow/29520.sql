
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 3  
),
TagPopularity AS (
    SELECT 
        Tag, COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  
)
SELECT 
    tp.Tag,
    tp.TagCount,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    COALESCE(SUM(c.Score), 0) AS TotalComments,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes
FROM 
    TagPopularity tp
JOIN 
    Posts p ON p.Tags LIKE '%' || tp.Tag || '%'  
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.PostTypeId = 1  
    AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
GROUP BY 
    tp.Tag, tp.TagCount
ORDER BY 
    tp.TagCount DESC;
