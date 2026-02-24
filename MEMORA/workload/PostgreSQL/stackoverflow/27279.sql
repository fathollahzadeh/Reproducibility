WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.LastActivityDate, 
        p.ViewCount, 
        p.Score, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01' 
        AND p.Score > 0 
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag
    FROM 
        RankedPosts
),
TagStats AS (
    SELECT 
        Tag, 
        COUNT(*) AS QuestionCount, 
        SUM(Score) AS TotalScore
    FROM 
        PopularTags pt
    JOIN 
        RankedPosts rp ON rp.Tags LIKE '%' || pt.Tag || '%'
    GROUP BY 
        Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    ts.Tag,
    ts.QuestionCount,
    ts.TotalScore
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON rp.Tags LIKE '%' || ts.Tag || '%'
WHERE 
    rp.TagRank <= 3 
ORDER BY 
    ts.TotalScore DESC, 
    rp.ViewCount DESC;