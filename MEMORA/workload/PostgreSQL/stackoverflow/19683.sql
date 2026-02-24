SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate,
    P.Score
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 10;