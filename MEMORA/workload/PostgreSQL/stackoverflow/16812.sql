SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    V.VoteTypeId 
FROM 
    Posts P 
JOIN 
    Users U ON P.OwnerUserId = U.Id 
JOIN 
    Votes V ON P.Id = V.PostId 
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC 
LIMIT 10;
