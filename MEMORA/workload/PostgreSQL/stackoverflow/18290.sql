SELECT 
    U.DisplayName AS UserDisplayName, 
    P.Title AS PostTitle, 
    P.CreationDate AS PostCreationDate, 
    P.Score AS PostScore 
FROM 
    Posts P 
JOIN 
    Users U ON P.OwnerUserId = U.Id 
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.Score DESC 
LIMIT 10;