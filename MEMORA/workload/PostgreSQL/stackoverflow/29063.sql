WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagInteraction AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        r.AnswerCount,
        r.CreationDate,
        r.OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS RelatedPostCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        Posts p ON p.ParentId = r.PostId
    JOIN 
        PostTypes pt ON r.Rank = 1 
    GROUP BY 
        r.PostId, r.Title, r.ViewCount, r.AnswerCount, r.CreationDate, r.OwnerDisplayName, pt.Name
)
SELECT 
    ti.PostId,
    ti.Title,
    ti.ViewCount,
    ti.AnswerCount,
    ti.CreationDate,
    ti.OwnerDisplayName,
    ti.PostTypeName,
    ti.RelatedPostCount,
    CASE 
        WHEN ti.ViewCount > 1000 THEN 'High'
        WHEN ti.ViewCount > 500 THEN 'Medium'
        ELSE 'Low'
    END AS PopularityRank
FROM 
    TagInteraction ti
WHERE 
    ti.RelatedPostCount > 0
ORDER BY 
    ti.ViewCount DESC
LIMIT 10;