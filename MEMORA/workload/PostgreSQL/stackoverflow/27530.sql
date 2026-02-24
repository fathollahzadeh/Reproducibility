WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS RN
    FROM 
        TagStats
)
SELECT 
    T.TagName,
    T.TotalViews,
    P.Title AS MostViewedPost,
    P.ViewCount AS PostViewCount
FROM 
    TopTags T
JOIN 
    Posts P ON P.Tags LIKE '%' || T.TagName || '%'
WHERE 
    T.RN <= 10 
ORDER BY 
    T.TotalViews DESC;