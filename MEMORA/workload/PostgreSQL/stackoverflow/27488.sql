WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.ViewCount > 100
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY (string_to_array(p.Tags, '><')::int[])
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS PopularityRank
    FROM 
        TagStats
    WHERE 
        PostCount > 0
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    pt.Name AS PostType,
    pTags.TagName,
    ptStats.PopularityRank
FROM 
    TopRankedPosts trp
JOIN 
    PostTypes pt ON trp.PostId = pt.Id
JOIN 
    (SELECT 
         trp.PostId, 
         unnest(string_to_array(trp.Tags, '><')) AS TagName
     FROM 
         TopRankedPosts trp) AS pTags ON trp.PostId = pTags.PostId
JOIN 
    PopularTags ptStats ON pTags.TagName = ptStats.TagName
ORDER BY 
    ptStats.PopularityRank, trp.Score DESC;