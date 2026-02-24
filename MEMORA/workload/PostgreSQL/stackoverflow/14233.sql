
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CM.Id) AS TotalComments,
    COUNT(V.Id) AS TotalVotes,
    SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    PH.CreationDate AS LastEditDate,
    PH.UserDisplayName AS LastEditor
FROM 
    Posts P
LEFT JOIN 
    Comments CM ON P.Id = CM.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    VoteTypes VT ON V.VoteTypeId = VT.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')  
GROUP BY 
    P.Id, 
    P.Title,
    P.CreationDate,
    U.DisplayName, 
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    PH.CreationDate, 
    PH.UserDisplayName
ORDER BY 
    P.CreationDate DESC;
