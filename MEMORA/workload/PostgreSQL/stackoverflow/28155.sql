WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
QuestionTags AS (
    SELECT 
        rp.PostId,
        UNNEST(STRING_TO_ARRAY(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags)-2), '><')) AS Tag
    FROM 
        RankedPosts rp
),
TagScores AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionsCount,
        SUM(rp.Score) AS TotalScore
    FROM 
        QuestionTags qt
    JOIN 
        RankedPosts rp ON qt.PostId = rp.PostId
    GROUP BY 
        Tag
)
SELECT 
    ts.Tag,
    ts.QuestionsCount,
    ts.TotalScore,
    CASE 
        WHEN ts.QuestionsCount > 0 THEN ts.TotalScore / ts.QuestionsCount 
        ELSE 0 
    END AS AverageScore
FROM 
    TagScores ts
ORDER BY 
    AverageScore DESC
LIMIT 10;