SELECT 
    P.Id AS PostId, 
    P.Title, 
    U.DisplayName AS OwnerName, 
    V.VoteTypeId, 
    V.CreationDate AS VoteDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 10;