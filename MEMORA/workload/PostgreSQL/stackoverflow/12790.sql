SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.Score,
    P.ViewCount,
    COALESCE(A.AnswerCount, 0) AS AnswerCount,
    COALESCE(C.CommentCount, 0) AS CommentCount,
    COALESCE(F.FavoriteCount, 0) AS FavoriteCount
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
         ParentId) A ON P.Id = A.ParentId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS FavoriteCount 
     FROM 
         Votes 
     WHERE 
         VoteTypeId = 5 
     GROUP BY 
         PostId) F ON P.Id = F.PostId
WHERE 
    P.PostTypeId = 1
ORDER BY 
    P.Score DESC 
LIMIT 100;
