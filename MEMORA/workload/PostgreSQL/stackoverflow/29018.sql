
WITH TagUsage AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '>_<')) AS Tag,
        Id AS PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(P.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(P.AnswerCount), 0) AS TotalAnswers
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(TU.PostId) AS UsageCount,
        COUNT(DISTINCT TU.PostId) AS DistinctPostCount,
        SUM(UA.TotalViews) AS TotalViews,
        SUM(UA.TotalComments) AS TotalComments
    FROM 
        TagUsage TU
    JOIN 
        Tags T ON TU.Tag = T.TagName
    JOIN 
        UserActivity UA ON TU.PostId = UA.UserId
    GROUP BY 
        T.TagName
)
SELECT 
    TS.TagName,
    TS.UsageCount,
    TS.DistinctPostCount,
    TS.TotalViews,
    TS.TotalComments,
    CASE WHEN TS.UsageCount > 100 THEN 'Very Popular'
         WHEN TS.UsageCount BETWEEN 50 AND 100 THEN 'Popular'
         ELSE 'Less Popular' END AS PopularityCategory
FROM 
    TagStats TS
ORDER BY 
    TS.UsageCount DESC;
