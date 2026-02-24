SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.CreationDate DESC
LIMIT 10;