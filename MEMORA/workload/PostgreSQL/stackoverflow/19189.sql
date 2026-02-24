SELECT 
    U.DisplayName,
    P.Title,
    P.CreationDate,
    P.Score,
    C.Text AS Comment,
    P.LastActivityDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.Score DESC, 
    P.CreationDate DESC
LIMIT 10;