SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Score
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  
ORDER BY 
    P.Score DESC
LIMIT 10;