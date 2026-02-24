SELECT 
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    PH.CreationDate AS HistoryCreationDate,
    P.Score AS PostScore,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName, U.Reputation, PH.CreationDate, P.Score
ORDER BY 
    P.CreationDate DESC
LIMIT 100;