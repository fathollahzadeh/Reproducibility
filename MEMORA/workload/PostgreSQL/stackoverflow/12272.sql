SELECT 
    U.Id AS UserId,
    U.Reputation,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.Reputation
ORDER BY 
    U.Reputation DESC, PostCount DESC;