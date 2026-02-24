
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.Id) AS CommentCount,
    SUM(V.BountyAmount) AS TotalBounty
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
