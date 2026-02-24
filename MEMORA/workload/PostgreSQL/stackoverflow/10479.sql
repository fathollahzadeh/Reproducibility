WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.CommentCount) AS AvgCommentsPerPost,
        AVG(P.AnswerCount) AS AvgAnswersPerQuestion
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalScore,
    UPS.TotalViews,
    UPS.AvgCommentsPerPost,
    UPS.AvgAnswersPerQuestion,
    RANK() OVER (ORDER BY UPS.TotalScore DESC) AS ScoreRank
FROM 
    UserPostStats UPS
ORDER BY 
    UPS.TotalScore DESC
LIMIT 10;