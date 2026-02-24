SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
    SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
    AVG(P.AnswerCount) AS AverageAnswers,
    AVG(P.CommentCount) AS AverageComments,
    AVG(P.FavoriteCount) AS AverageFavorites,
    U.Reputation AS UserReputation,
    COUNT(DISTINCT U.Id) AS ActiveUsers
FROM 
    Posts P
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
GROUP BY 
    PT.Name, U.Reputation
ORDER BY 
    TotalPosts DESC;