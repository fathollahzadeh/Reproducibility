SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    P.PostTypeId,
    PT.Name AS PostTypeName,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.Score IS NOT NULL THEN 1 ELSE 0 END) AS TotalScore,
    SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
    SUM(CASE WHEN P.AnswerCount IS NOT NULL THEN P.AnswerCount ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.CommentCount IS NOT NULL THEN P.CommentCount ELSE 0 END) AS TotalComments
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, P.PostTypeId, PT.Name
ORDER BY 
    U.Reputation DESC, TotalPosts DESC;