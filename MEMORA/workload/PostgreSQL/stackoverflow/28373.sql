
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
), TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS QuestionCount,
        SUM(Score) AS TotalScore
    FROM (
        SELECT 
            UNNEST(string_to_array(TRANSLATE(Tags, '<>', ''), '><')) AS TagName,
            Score
        FROM 
            RankedPosts
    ) AS UnnestedTags
    GROUP BY 
        TagName
), TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tt.TagName,
    tt.QuestionCount,
    tt.TotalScore,
    CASE
        WHEN tt.QuestionCount > 50 THEN 'Active'
        WHEN tt.QuestionCount > 10 THEN 'Moderate'
        ELSE 'Inactive'
    END AS TagActivityStatus
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10 
ORDER BY 
    tt.TotalScore DESC;
