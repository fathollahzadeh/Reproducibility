
SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS OwnerName, 
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    P.Title, 
    P.CreationDate, 
    U.DisplayName
ORDER BY 
    P.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;
