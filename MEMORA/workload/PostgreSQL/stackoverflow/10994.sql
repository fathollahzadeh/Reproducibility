WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        U.Id, U.DisplayName, PT.Name
)
SELECT 
    UserId,
    DisplayName,
    PostType,
    PostCount,
    TotalScore,
    TotalViews,
    TotalAnswers,
    TotalComments
FROM 
    UserPostStats
ORDER BY 
    TotalScore DESC, PostCount DESC;