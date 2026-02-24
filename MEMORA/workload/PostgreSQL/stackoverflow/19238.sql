SELECT 
    P.Id AS PostID,
    P.Title,
    U.DisplayName AS Owner,
    P.Score,
    P.ViewCount,
    P.CreationDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 10;