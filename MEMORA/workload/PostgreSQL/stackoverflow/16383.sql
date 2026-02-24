
SELECT 
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    P.Score,
    P.ViewCount,
    COUNT(A.Id) AS AnswerCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
WHERE 
    P.PostTypeId = 1
GROUP BY 
    P.Title, P.CreationDate, U.DisplayName, P.Score, P.ViewCount
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
