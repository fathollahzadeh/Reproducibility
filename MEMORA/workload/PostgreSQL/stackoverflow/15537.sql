SELECT 
    U.DisplayName,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    COUNT(C.ID) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.Score, P.ViewCount
ORDER BY 
    P.CreationDate DESC
LIMIT 10;