
SELECT 
    P.Title, 
    U.DisplayName AS Owner, 
    P.CreationDate, 
    P.Score, 
    COUNT(C.Id) AS CommentCount 
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    P.Title, U.DisplayName, P.CreationDate, P.Score, P.Id
ORDER BY 
    P.CreationDate DESC 
LIMIT 10;
