WITH TagCounts AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.AnswerCount) AS AverageAnswers
    FROM 
        Tags T
        LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        AverageAnswers,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagCounts
),
UserEngagement AS (
    SELECT 
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS NumberOfPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users U
        JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.DisplayName
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalViews,
    TT.TotalScore,
    TT.AverageAnswers,
    UE.DisplayName,
    UE.TotalViews AS UserTotalViews,
    UE.NumberOfPosts AS UserNumberOfPosts,
    UE.PositivePosts AS UserPositivePosts,
    UE.NegativePosts AS UserNegativePosts
FROM 
    TopTags TT
    JOIN UserEngagement UE ON UE.NumberOfPosts > 10 
WHERE 
    TT.Rank <= 10 
ORDER BY 
    TT.TotalScore DESC, UE.TotalViews DESC;