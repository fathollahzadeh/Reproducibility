
SELECT 
    P.Id AS PostId,
    P.Title,
    U.Id AS UserId,
    U.DisplayName AS Author,
    COUNT(C.ID) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    P.CreationDate,
    P.LastActivityDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id, P.Title, U.Id, U.DisplayName, P.CreationDate, P.LastActivityDate, P.Score, P.ViewCount, P.AnswerCount
ORDER BY 
    P.Score DESC, P.CreationDate DESC
LIMIT 100;
