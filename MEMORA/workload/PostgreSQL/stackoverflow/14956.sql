SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    C.Id AS CommentId,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate,
    PH.CreationDate AS PostHistoryDate,
    PHT.Name AS PostHistoryType
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
ORDER BY 
    P.CreationDate DESC
LIMIT 100;