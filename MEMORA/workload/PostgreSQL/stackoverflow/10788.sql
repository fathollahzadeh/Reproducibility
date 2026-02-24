WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserCommentStats AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS TotalComments
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
FinalResults AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalViews,
        UPS.TotalScore,
        COALESCE(UCS.TotalComments, 0) AS TotalComments
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        UserCommentStats UCS ON UPS.UserId = UCS.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalComments, 
    TotalViews, 
    TotalScore
FROM 
    FinalResults
ORDER BY 
    TotalScore DESC;