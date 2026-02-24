SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    PH.CreationDate AS PostHistoryDate,
    P.Body AS PostBody,
    PH.Comment AS EditComment,
    P.Score AS PostScore,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
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
WHERE 
    PH.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, PH.CreationDate, P.Body, PH.Comment, P.Score
ORDER BY 
    PH.CreationDate DESC
LIMIT 100;