
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerUser,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS RankYearly
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE('2024-10-01') - INTERVAL '5 years'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.OwnerUser,
    pt.TagName,
    ast.AnswerCount AS RelatedAnswerCount,
    rp.RankYearly
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.ViewCount > 100 
LEFT JOIN 
    AnswerStats ast ON rp.PostId = ast.PostId
WHERE 
    rp.RankYearly <= 3 
ORDER BY 
    rp.CreationDate DESC, rp.ViewCount DESC;
