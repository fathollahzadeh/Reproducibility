
WITH RecursiveTagCounts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        ARRAY_LENGTH(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'), 1) AS TagCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
), 
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        SUM(R.TagCount) AS TotalQuestionsWithTag
    FROM 
        Tags T
    JOIN 
        RecursiveTagCounts R ON R.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
)

SELECT 
    U.DisplayName,
    U.TotalQuestions,
    U.TotalUpvotes,
    U.TotalDownvotes,
    T.TagName,
    T.TotalQuestionsWithTag,
    ROUND((U.TotalUpvotes::decimal / NULLIF(U.TotalQuestions, 0)) * 100, 2) AS UpvotePercentage,
    ROUND((U.TotalDownvotes::decimal / NULLIF(U.TotalQuestions, 0)) * 100, 2) AS DownvotePercentage
FROM 
    UserActivity U
LEFT JOIN 
    TagStats T ON U.TotalQuestions > 0
ORDER BY 
    U.TotalQuestions DESC, 
    T.TotalQuestionsWithTag DESC
LIMIT 10;
