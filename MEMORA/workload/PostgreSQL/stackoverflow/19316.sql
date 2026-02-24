SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    C.Text AS CommentText, 
    C.CreationDate AS CommentDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 10;