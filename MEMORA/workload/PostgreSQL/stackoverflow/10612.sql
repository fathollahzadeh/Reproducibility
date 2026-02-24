SELECT 
    U.Id AS UserId,
    U.DisplayName AS UserName,
    U.Reputation,
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score AS PostScore,
    PH.CreationDate AS PostHistoryDate,
    PHT.Name AS PostHistoryType,
    COUNT(COALESCE(CM.Id, 0)) AS CommentCount,
    COUNT(COALESCE(V.Id, 0)) AS VoteCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
LEFT JOIN 
    Comments CM ON P.Id = CM.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, PH.CreationDate, PHT.Name
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC;