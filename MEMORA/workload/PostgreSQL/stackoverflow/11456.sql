WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalPositiveScore,
        SUM(CASE WHEN P.CommentCount > 0 THEN 1 ELSE 0 END) AS TotalPostsWithComments,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalPositiveScore,
    U.TotalPostsWithComments,
    U.AverageScore,
    T.TagName,
    T.TotalPosts AS TagTotalPosts,
    T.AverageScore AS TagAverageScore
FROM 
    UserPostStats U
JOIN 
    TagStats T ON U.TotalPosts > 0  
ORDER BY 
    U.TotalPosts DESC, T.TotalPosts DESC
LIMIT 100;