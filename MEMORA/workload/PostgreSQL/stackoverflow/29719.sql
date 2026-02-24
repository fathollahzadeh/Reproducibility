
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') 
        AND p.Score >= 0
),
TagSummary AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedCount,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts
    GROUP BY 
        UNNEST(string_to_array(Tags, ','))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        UpvotedCount,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagSummary
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.UpvotedCount,
    tt.AverageScore,
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score
FROM 
    TopTags tt
JOIN 
    RankedPosts rp ON rp.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    tt.TagRank, rp.CreationDate DESC;
