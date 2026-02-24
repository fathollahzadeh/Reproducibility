SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS OwnerDisplayName,
    PT.Name AS PostTypeName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    P.Score > 0
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
