SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate AS UserCreationDate,
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    P.CommentCount,
    P.AnswerCount,
    PH.CreationDate AS PostHistoryDate,
    PHT.Name AS PostHistoryType,
    COUNT(CM.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount
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
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, 
    P.CommentCount, P.AnswerCount, PH.CreationDate, PHT.Name
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC;