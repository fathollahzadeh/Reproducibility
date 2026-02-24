
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.Body IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CreationDate,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
),
TagCounts AS (
    SELECT 
        TRIM(tag) AS TagName,
        COUNT(*) AS Count
    FROM 
        FilteredPosts,
        UNNEST(string_to_array(Tags, ',')) AS tag
    GROUP BY 
        TRIM(tag)
),
PopularTags AS (
    SELECT 
        TagName,
        Count,
        DENSE_RANK() OVER (ORDER BY Count DESC) AS TagRank
    FROM 
        TagCounts
)
SELECT 
    pt.TagName,
    pt.Count AS TagUsageCount,
    fp.Author,
    COUNT(fp.PostId) AS NumberOfPosts,
    SUM(fp.Score) AS TotalScore
FROM 
    PopularTags pt
JOIN 
    FilteredPosts fp ON pt.TagName = ANY(string_to_array(fp.Tags, ','))
WHERE 
    pt.TagRank <= 10  
GROUP BY 
    pt.TagName, pt.Count, fp.Author
ORDER BY 
    TagUsageCount DESC, TotalScore DESC;
