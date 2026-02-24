
SELECT 
    U.DisplayName,
    COUNT(P.Id) AS NumberOfPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS NumberOfQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS NumberOfAnswers,
    AVG(U.Reputation) AS AverageReputation
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    NumberOfPosts DESC
LIMIT 10;
