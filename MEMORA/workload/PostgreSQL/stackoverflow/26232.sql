WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPostsCount,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
PopularTags AS (
    SELECT 
        TagName
    FROM 
        TagStats
    WHERE 
        PopularPostsCount > 5
),
MostActiveUsers AS (
    SELECT 
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AveragePostScore
    FROM 
        Users U
    JOIN 
        Posts P ON P.OwnerUserId = U.Id
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
CombinedStats AS (
    SELECT 
        PT.TagName,
        AU.DisplayName,
        AU.PostCount,
        AU.TotalViews,
        AU.AveragePostScore,
        TS.AverageUserReputation
    FROM 
        PopularTags PT
    JOIN 
        TagStats TS ON PT.TagName = TS.TagName
    JOIN 
        MostActiveUsers AU ON AU.TotalViews > 10000
)

SELECT 
    CT.TagName,
    CT.DisplayName,
    CT.PostCount,
    CT.TotalViews,
    CT.AveragePostScore,
    CT.AverageUserReputation
FROM 
    CombinedStats CT
ORDER BY 
    CT.AveragePostScore DESC, CT.TotalViews DESC;
