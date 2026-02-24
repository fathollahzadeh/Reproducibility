WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount,
        SUM(CASE WHEN rp.ScoreRank = 1 THEN 1 ELSE 0 END) AS TopScoreQuestions
    FROM 
        FilteredTags ft
    JOIN 
        RankedPosts rp ON ft.PostId = rp.PostId
    GROUP BY 
        Tag
), 
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        TopScoreQuestions,
        ROW_NUMBER() OVER (ORDER BY TopScoreQuestions DESC, TagCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    tt.Tag,
    tt.TagCount,
    tt.TopScoreQuestions,
    CONCAT('Tag ', tt.Tag, ' was used in ', tt.TagCount, ' questions and had ', tt.TopScoreQuestions, ' top scoring questions.') AS BenchmarkSummary
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.TagCount DESC;