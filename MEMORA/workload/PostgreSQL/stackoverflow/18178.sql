SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.Score,
    P.ViewCount,
    P.CreationDate,
    T.TagName
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
JOIN 
    Tags T ON T.ExcerptPostId = P.Id
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.Score DESC
LIMIT 10;