
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.Reputation AS OwnerReputation,
    COUNT(C.ID) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    PT.Name AS PostTypeName,
    P.LastActivityDate,
    PH.CreationDate AS LastEditDate,
    PH.Comment AS LastEditComment
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
WHERE 
    P.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days' 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, 
    PT.Name, P.LastActivityDate, PH.CreationDate, PH.Comment
ORDER BY 
    P.LastActivityDate DESC
LIMIT 100;
