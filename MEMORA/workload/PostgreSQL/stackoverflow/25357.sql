
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
TagAnalysis AS (
    SELECT 
        unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))
)
SELECT 
    ra.OwnerDisplayName,
    ra.Title,
    ra.PostId,
    ra.CreationDate,
    ra.ViewCount,
    ra.Score,
    ta.Tag,
    ta.PostCount,
    ta.AverageViewCount,
    ta.AverageScore
FROM 
    RankedPosts ra
JOIN 
    TagAnalysis ta ON ra.Tags LIKE '%' || ta.Tag || '%'
WHERE 
    ra.TagRank <= 3 
ORDER BY 
    ta.PostCount DESC, 
    ra.ViewCount DESC;
