SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(DISTINCT V.Id) AS VoteCount,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    MAX(P.LastActivityDate) AS LastActivityDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.CreationDate >= '2023-01-01' 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.Score, P.ViewCount
ORDER BY 
    PostScore DESC, PostViewCount DESC;