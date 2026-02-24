SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.Score AS PostScore,
    PH.CreationDate AS HistoryCreationDate,
    P.LastEditDate AS LastEditDate,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    P.CreationDate >= '2023-01-01'
GROUP BY 
    U.DisplayName, P.Title, P.Score, PH.CreationDate, P.LastEditDate
ORDER BY 
    P.Score DESC, UserName ASC;
