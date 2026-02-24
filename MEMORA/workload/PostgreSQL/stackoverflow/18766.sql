SELECT 
    P.Id AS PostId, 
    P.Title, 
    U.DisplayName AS OwnerName, 
    P.CreationDate, 
    P.ViewCount, 
    P.Score
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  
ORDER BY 
    P.CreationDate DESC
LIMIT 10;