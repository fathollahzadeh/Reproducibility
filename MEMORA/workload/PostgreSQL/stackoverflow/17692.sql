SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate,
    COUNT(C.Id) AS CommentCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    U.DisplayName, U.Reputation, P.Title, P.CreationDate
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC
LIMIT 10;