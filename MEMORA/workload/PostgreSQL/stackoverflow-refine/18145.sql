SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate,
    P.Score,
    P.ViewCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  
ORDER BY 
    P.CreationDate DESC
LIMIT 10;