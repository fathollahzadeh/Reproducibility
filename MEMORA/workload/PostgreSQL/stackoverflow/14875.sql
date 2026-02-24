
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN V.PostId IS NOT NULL THEN 1 END) AS VoteCount,
    COUNT(CASE WHEN PH.PostId IS NOT NULL THEN 1 END) AS HistoryCount
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score, P.ViewCount
ORDER BY 
    P.CreationDate DESC;
