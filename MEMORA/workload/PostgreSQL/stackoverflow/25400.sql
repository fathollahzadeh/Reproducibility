SELECT 
    U.DisplayName AS UserDisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    COUNT(DISTINCT PH.Id) AS TotalPostHistoryEntries,
    STRING_AGG(DISTINCT PT.Name, ', ') AS PostTypeNames, 
    AVG(U.Reputation) AS AverageUserReputation,
    AVG(COALESCE(P.Score, 0)) AS AveragePostScore,
    MIN(P.CreationDate) AS EarliestPostDate,
    MAX(P.LastActivityDate) AS LatestPostDate
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    U.Reputation > 100
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC, AveragePostScore DESC;