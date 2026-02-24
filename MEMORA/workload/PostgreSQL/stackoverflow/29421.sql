WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        AverageReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts,
        RANK() OVER (ORDER BY TotalScore DESC) AS RankByScore
    FROM 
        TagStats
),
CombinedStats AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        AverageReputation,
        RankByPosts,
        RankByScore
    FROM 
        TopTags
    WHERE 
        RankByPosts <= 10 OR RankByScore <= 10
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    AverageReputation,
    RankByPosts,
    RankByScore
FROM 
    CombinedStats
ORDER BY 
    COALESCE(RankByPosts, 999), COALESCE(RankByScore, 999);
