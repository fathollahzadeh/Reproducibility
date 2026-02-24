WITH ParsedTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        ParsedTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount
    FROM 
        TagCounts
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
TagDetails AS (
    SELECT 
        p.Title,
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        t.Tag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        ParsedTags pt ON p.Id = pt.PostId
    JOIN 
        TopTags t ON pt.Tag = t.Tag
)
SELECT
    Tag,
    COUNT(*) AS PostCount,
    AVG(Score) AS AverageScore,
    MIN(CreationDate) AS EarliestCreation,
    MAX(CreationDate) AS LatestCreation,
    STRING_AGG(DISTINCT Title, '; ') AS RelatedPostTitles,
    STRING_AGG(DISTINCT OwnerDisplayName, '; ') AS Contributors
FROM
    TagDetails
GROUP BY 
    Tag
ORDER BY 
    PostCount DESC;