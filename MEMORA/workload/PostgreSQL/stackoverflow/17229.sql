SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 10;