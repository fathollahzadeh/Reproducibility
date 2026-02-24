
SELECT 
    P.Title,
    P.CreationDate,
    P.Score,
    U.DisplayName AS OwnerName,
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
    P.Title, P.CreationDate, P.Score, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
