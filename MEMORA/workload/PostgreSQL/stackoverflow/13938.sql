SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.Score,
    P.ViewCount,
    COALESCE(AC.AnswerCount, 0) AS AnswerCount,
    COALESCE(C.CommentCount, 0) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT 
         ParentId,
         COUNT(*) AS AnswerCount
     FROM 
         Posts
     WHERE 
         PostTypeId = 2  
     GROUP BY 
         ParentId) AC ON P.Id = AC.ParentId
LEFT JOIN 
    (SELECT 
         PostId,
         COUNT(*) AS CommentCount
     FROM 
         Comments
     GROUP BY 
         PostId) C ON P.Id = C.PostId
WHERE 
    P.CreationDate >= '2022-01-01'  
ORDER BY 
    P.Score DESC, P.ViewCount DESC;