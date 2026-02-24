SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COALESCE(CA.CommentCount, 0) AS TotalCommentCount,
    COALESCE(B.BadgeCount, 0) AS TotalBadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) CA ON P.Id = CA.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(Id) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) B ON U.Id = B.UserId
WHERE 
    P.CreationDate >= '2023-01-01'  
ORDER BY 
    P.ViewCount DESC  
LIMIT 100;