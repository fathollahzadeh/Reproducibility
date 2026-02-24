
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts ah ON p.Id = ah.AcceptedAnswerId
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.Score) AS AverageScore
    FROM 
        RankedPosts rp
    INNER JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalScore,
        AverageScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalScore,
    tt.AverageScore,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.Title AS PostTitle,
    rp.PostId AS QuestionId,
    rp.AcceptedAnswerId
FROM 
    TopTags tt
JOIN 
    RankedPosts rp ON rp.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    tt.TotalScore DESC, 
    rp.Score DESC;
