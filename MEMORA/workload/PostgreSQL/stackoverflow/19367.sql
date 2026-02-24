SELECT 
    P.Title, 
    P.CreationDate, 
    U.DisplayName AS OwnerName, 
    P.Score, 
    P.ViewCount, 
    P.AnswerCount 
FROM 
    Posts P 
JOIN 
    Users U ON P.OwnerUserId = U.Id 
WHERE 
    P.PostTypeId = 1  
ORDER BY 
    P.CreationDate DESC 
LIMIT 10;