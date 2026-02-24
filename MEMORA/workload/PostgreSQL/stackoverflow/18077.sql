
SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS Author, 
    PT.Name AS PostType, 
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    P.Title, P.CreationDate, U.DisplayName, PT.Name
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
