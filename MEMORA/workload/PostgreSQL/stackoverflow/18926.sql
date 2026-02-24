SELECT 
    U.DisplayName AS UserName, 
    P.Title AS PostTitle, 
    P.CreationDate AS PostDate, 
    P.ViewCount, 
    P.Score 
FROM 
    Users U 
JOIN 
    Posts P ON U.Id = P.OwnerUserId 
WHERE 
    P.PostTypeId = 1 
ORDER BY 
    P.Score DESC 
LIMIT 10;
