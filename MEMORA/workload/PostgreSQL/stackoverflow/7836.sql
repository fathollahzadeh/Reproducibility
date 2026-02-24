SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts,
    AVG(COALESCE(P.ViewCount, 0)) AS AverageViews,
    AVG(COALESCE(P.Score, 0)) AS AverageScore
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) 
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING 
    COUNT(DISTINCT P.Id) > 10 
ORDER BY 
    TotalPosts DESC, U.Reputation DESC
LIMIT 50;