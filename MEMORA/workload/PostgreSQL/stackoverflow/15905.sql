
SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
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
    P.Id, P.Title, P.ViewCount, U.DisplayName, P.CreationDate
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
