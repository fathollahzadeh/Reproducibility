SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Id AS PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    C.Id AS CommentId,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC, 
    P.CreationDate DESC 
LIMIT 100;