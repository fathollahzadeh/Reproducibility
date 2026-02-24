
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewPosts
    FROM
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TagPopularity AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%') 
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagPopularity
    WHERE 
        PostCount > 10 
)
SELECT 
    UPS.DisplayName,
    UPS.Reputation,
    UPS.TotalPosts,
    UPS.QuestionCount,
    UPS.AnswerCount,
    UPS.PositivePosts,
    UPS.HighViewPosts,
    TT.TagName,
    TT.PostCount,
    TT.TotalViews,
    TT.TotalAnswers
FROM 
    UserPostStats UPS
JOIN 
    TopTags TT ON UPS.QuestionCount > 0 
ORDER BY 
    UPS.Reputation DESC, TT.PostCount DESC
LIMIT 20;
