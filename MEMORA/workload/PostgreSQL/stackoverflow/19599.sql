SELECT 
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    PT.Name AS PostTypeName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    P.Score > 10
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
