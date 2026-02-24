
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.FavoriteCount,
    P.LastActivityDate
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'  
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName, P.Score, P.ViewCount, P.AnswerCount, P.FavoriteCount, P.LastActivityDate
ORDER BY 
    P.Score DESC, P.ViewCount DESC;
