SELECT 
    U.DisplayName,
    P.Title,
    P.CreationDate,
    P.Score,
    COUNT(C.CommentId) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS CommentId FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.Score
ORDER BY 
    P.CreationDate DESC
LIMIT 10;