
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate AS PostCreationDate,
    COUNT(V.Id) AS VoteCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    U.Reputation >= 100 
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, P.Id, P.Title, P.CreationDate
ORDER BY 
    U.Reputation DESC, VoteCount DESC;
