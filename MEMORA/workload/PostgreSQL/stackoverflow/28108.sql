WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.ViewCount > 0
),

TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        rn <= 10 
),

TagAnalytics AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        TopRankedPosts
    GROUP BY 
        Tag
)

SELECT 
    t.Tag,
    t.PostCount,
    t.TotalViews,
    t.TotalScore,
    (SELECT COUNT(*) FROM Tags WHERE TagName = t.Tag) AS TagExists,
    (SELECT COUNT(*) FROM Posts p WHERE p.Tags LIKE '%' || t.Tag || '%') AS PostsWithTag
FROM 
    TagAnalytics t
ORDER BY 
    TotalScore DESC,
    TotalViews DESC
LIMIT 20;