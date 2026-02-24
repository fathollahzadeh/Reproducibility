
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><'))
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        TagStats
)
SELECT 
    t.Tag,
    t.PostCount,
    t.TotalViews,
    t.TotalScore,
    t.ViewRank,
    t.ScoreRank,
    (SELECT STRING_AGG(r.OwnerDisplayName, ', ') FROM RankedPosts r WHERE r.Tags LIKE '%' || t.Tag || '%') AS TopPostOwners
FROM 
    TopTags t
WHERE 
    t.PostCount > 5 
ORDER BY 
    t.TotalViews DESC, t.TotalScore DESC;
