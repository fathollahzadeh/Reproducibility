WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopUsers,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        T.Count > 0
    GROUP BY 
        T.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        TopUsers,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS Rank
    FROM 
        TagStatistics
)

SELECT 
    PT.TagName,
    PT.PostCount,
    PT.TotalViews,
    PT.AverageScore,
    PT.TopUsers,
    PT.CommentCount
FROM 
    PopularTags PT
WHERE 
    PT.Rank <= 10
ORDER BY 
    PT.AverageScore DESC, PT.TotalViews DESC;
