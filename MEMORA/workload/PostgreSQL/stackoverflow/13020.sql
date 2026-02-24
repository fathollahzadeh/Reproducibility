SELECT 
    PH.PostHistoryTypeId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
FROM 
    Posts P
JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    PH.CreationDate BETWEEN '2022-01-01' AND '2023-01-01'
GROUP BY 
    PH.PostHistoryTypeId, P.Title, P.CreationDate, P.ViewCount
ORDER BY 
    P.CreationDate;
