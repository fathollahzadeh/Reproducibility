WITH TitleStats AS (
    SELECT 
        AVG(LENGTH(Title)) AS AvgTitleLength,
        MIN(LENGTH(Title)) AS MinTitleLength,
        MAX(LENGTH(Title)) AS MaxTitleLength,
        COUNT(*) AS TitleCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
BodyStats AS (
    SELECT 
        AVG(LENGTH(Body)) AS AvgBodyLength,
        MIN(LENGTH(Body)) AS MinBodyLength,
        MAX(LENGTH(Body)) AS MaxBodyLength,
        COUNT(*) AS BodyCount
    FROM 
        Posts
    WHERE 
        PostTypeId IN (1, 2) 
),
TagStats AS (
    SELECT 
        COUNT(DISTINCT Tags) AS DistinctTagCount,
        SUM(LENGTH(Tags) - LENGTH(REPLACE(Tags, '<', '')) / LENGTH('<')) AS TagCount
        
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
CombinedStats AS (
    SELECT 
        t.AvgTitleLength, 
        t.MinTitleLength, 
        t.MaxTitleLength,
        b.AvgBodyLength, 
        b.MinBodyLength, 
        b.MaxBodyLength,
        tg.DistinctTagCount,
        tg.TagCount
    FROM 
        TitleStats t, BodyStats b, TagStats tg
)

SELECT 
    AvgTitleLength, 
    MinTitleLength, 
    MaxTitleLength, 
    AvgBodyLength, 
    MinBodyLength, 
    MaxBodyLength, 
    DistinctTagCount, 
    TagCount 
FROM 
    CombinedStats;