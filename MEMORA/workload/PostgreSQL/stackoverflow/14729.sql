SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    P.Id AS PostId,
    P.Title,
    P.PostTypeId,
    PT.Name AS PostTypeName,
    P.Score AS PostScore,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, P.Id, P.Title, P.PostTypeId, PT.Name, P.Score, P.CreationDate, P.ViewCount
ORDER BY 
    U.Reputation DESC, P.Score DESC;