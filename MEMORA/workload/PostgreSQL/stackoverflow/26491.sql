
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
TagStats AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TotalPosts,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts 
    WHERE 
        TagRank <= 5  
    GROUP BY 
        TagName
),
FinalResult AS (
    SELECT 
        ts.TagName,
        ts.TotalPosts,
        ts.TotalScore,
        ts.TotalViews,
        CASE 
            WHEN ts.TotalPosts > 20 THEN 'Very Active'
            WHEN ts.TotalPosts BETWEEN 10 AND 20 THEN 'Moderately Active'
            ELSE 'Less Active' 
        END AS ActivityLevel
    FROM 
        TagStats ts
)
SELECT 
    TagName,
    TotalPosts,
    TotalScore,
    TotalViews,
    ActivityLevel
FROM 
    FinalResult
ORDER BY 
    TotalPosts DESC, 
    TotalScore DESC;
