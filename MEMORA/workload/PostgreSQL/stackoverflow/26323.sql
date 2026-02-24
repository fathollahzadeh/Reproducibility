WITH TagStats AS (
    SELECT 
        TRIM(REGEXP_REPLACE(Tags, '<[^>]*>', '', 'g')) AS CleanTags,
        COUNT(*) AS PostCount,
        SUM(COALESCE(ViewCount, 0)) AS TotalViews,
        AVG(SCORE) AS AvgScore
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        CleanTags
), 
TagCount AS (
    SELECT 
        CleanTags,
        PostCount,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (
            ORDER BY 
                TotalViews DESC, PostCount DESC, AvgScore DESC
        ) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 5 
), 
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM 
        UserEngagement
)
SELECT 
    TU.CleanTags,
    TU.PostCount,
    TU.TotalViews,
    TU.AvgScore,
    PU.DisplayName,
    PU.TotalPosts,
    PU.TotalAnswers,
    PU.TotalQuestions,
    PU.TotalComments
FROM 
    TagCount TU
JOIN 
    PopularUsers PU ON PU.TotalPosts > 10
WHERE 
    TU.Rank <= 10 
ORDER BY 
    TU.TotalViews DESC