SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
    SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.ViewCount ELSE 0 END) AS TotalViews
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    U.Reputation > 0  
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC
LIMIT 100;