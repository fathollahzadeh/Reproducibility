
SELECT 
    P.Id AS PostID,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.Id) AS CommentCount,
    COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
LEFT JOIN 
    Badges B ON U.Id = B.UserId
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
