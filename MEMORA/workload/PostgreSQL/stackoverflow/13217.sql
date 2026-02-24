SELECT 
    U.Id AS UserId, 
    U.DisplayName, 
    U.Reputation, 
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(P.Score) AS TotalScore,
    SUM(P.ViewCount) AS TotalViews,
    AVG(P.AnswerCount) AS AvgAnswersPerQuestion,
    AVG(P.CommentCount) AS AvgCommentsPerPost,
    COUNT(DISTINCT B.Id) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, TotalScore DESC;