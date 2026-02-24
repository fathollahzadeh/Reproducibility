WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagPopularities AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
LatestPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerDisplayName,
        pt.QuestionCount
    FROM 
        Posts p
    INNER JOIN 
        TagPopularities pt ON pt.Tag = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.LastActivityDate DESC
    LIMIT 5 
)
SELECT 
    lp.Title AS RecentQuestion,
    lp.CreationDate AS PostedOn,
    lp.ViewCount AS Views,
    lp.OwnerDisplayName AS Author,
    tp.Tag AS PopularTag,
    tp.QuestionCount AS TagUsage 
FROM 
    LatestPosts lp
JOIN 
    TagPopularities tp ON lp.QuestionCount = tp.QuestionCount 
ORDER BY 
    lp.CreationDate DESC;