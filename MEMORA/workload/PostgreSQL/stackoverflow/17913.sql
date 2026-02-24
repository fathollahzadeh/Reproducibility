
SELECT 
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount 
     FROM Votes 
     GROUP BY PostId) V ON P.Id = V.PostId
WHERE 
    U.Reputation > 100
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalVotes DESC;
