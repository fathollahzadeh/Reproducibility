WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
),
PopularTagStats AS (
    SELECT 
        T.TagName,
        COUNT(RP.PostId) AS PostCount,
        SUM(RP.ViewCount) AS TotalViews,
        AVG(RP.Score) AS AverageScore
    FROM 
        RankedPosts RP
    JOIN 
        UNNEST(string_to_array(RP.Tags, '><')) AS T(TagName) 
    ON 
        RP.TagRank = 1 
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        PopularTagStats
)

SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalViews,
    TT.AverageScore,
    CASE 
        WHEN TT.Rank <= 5 THEN 'Top Tag'
        WHEN TT.Rank <= 10 THEN 'Popular Tag'
        ELSE 'Emerging Tag'
    END AS TagCategory
FROM 
    TopTags TT
WHERE 
    TT.PostCount > 10 
ORDER BY 
    TT.Rank;