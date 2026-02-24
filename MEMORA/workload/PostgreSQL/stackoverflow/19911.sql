
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2 
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id, P.Title, U.DisplayName, P.CreationDate, P.ViewCount, P.Score
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
