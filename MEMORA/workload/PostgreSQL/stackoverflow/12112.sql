
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS Owner,
    P.CreationDate,
    COUNT(CF.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    P.ViewCount
FROM 
    Posts P
LEFT JOIN 
    Comments CF ON P.Id = CF.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= '2022-01-01' 
GROUP BY 
    P.Id, P.Title, U.DisplayName, P.CreationDate, P.ViewCount
ORDER BY 
    P.CreationDate DESC;
