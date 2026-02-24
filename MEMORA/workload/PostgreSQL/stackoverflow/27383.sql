WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Tags IS NOT NULL
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' from Tags), '> <')) AS Tag,
        PostId
    FROM 
        TaggedPosts
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(AnswerCount) AS AvgAnswerCount
    FROM 
        TagCounts tc
    JOIN 
        TaggedPosts tp ON tc.PostId = tp.PostId
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        AvgViewCount,
        AvgAnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    t.Tag,
    t.PostCount,
    t.AvgViewCount,
    t.AvgAnswerCount
FROM 
    PopularTags t
WHERE 
    t.TagRank <= 10  
ORDER BY 
    t.PostCount DESC;