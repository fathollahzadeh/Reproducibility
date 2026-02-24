SELECT 
    U.DisplayName AS UserDisplayName, 
    P.Title AS PostTitle, 
    P.CreationDate AS PostCreationDate, 
    P.Score AS PostScore, 
    C.Text AS CommentText, 
    C.CreationDate AS CommentCreationDate
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1  
ORDER BY 
    C.CreationDate DESC
LIMIT 10;