
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
    SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS TotalAnswersToQuestions,
    SUM(P.ViewCount) AS TotalViewCount,
    SUM(P.FavoriteCount) AS TotalFavorites,
    MAX(P.LastActivityDate) AS LastActivityDate,
    MIN(P.CreationDate) AS FirstPostDate,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC, TotalPosts DESC;
