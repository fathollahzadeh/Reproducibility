
SELECT 
    U.Reputation AS UserReputation,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
    AVG(P.Score) AS AveragePostScore,
    MAX(P.CreationDate) AS MostRecentPost,
    COUNT(DISTINCT V.UserId) AS UniqueVoters
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.Reputation
ORDER BY 
    UserReputation DESC;
