
SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS Owner, 
    COUNT(C.Id) AS CommentCount, 
    COUNT(V.Id) AS VoteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    P.Title, P.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
