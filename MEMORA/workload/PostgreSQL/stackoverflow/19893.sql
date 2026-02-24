SELECT 
    U.DisplayName AS UserName, 
    P.Title AS PostTitle, 
    P.Score AS PostScore, 
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
    P.Score DESC
LIMIT 10;