SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS NumberOfPosts,
    AVG(U.Reputation) AS AverageReputation,
    SUM(V.TotalVotes) AS TotalVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    (SELECT 
         PostId,
         COUNT(*) AS TotalVotes
     FROM 
         Votes
     GROUP BY 
         PostId) V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    NumberOfPosts DESC;