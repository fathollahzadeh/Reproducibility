
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.Id AS UserId,
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    P.ViewCount,
    P.Score,
    COALESCE(COUNT(V.Id), 0) AS VoteCount,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    COALESCE(P.AnswerCount, 0) AS AnswerCount,
    COALESCE(P.CommentCount, 0) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2023-01-01'  
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.Id, U.DisplayName, U.Reputation, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
