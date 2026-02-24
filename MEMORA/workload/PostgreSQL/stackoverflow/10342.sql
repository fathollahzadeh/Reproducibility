SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    COUNT(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers,
    AVG(U.Reputation) AS AverageReputation
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC
LIMIT 100;