SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    PH.CreationDate AS LastEditDate,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId IN (4, 5, 6) 
LEFT JOIN 
    Votes V ON V.PostId = P.Id
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, U.DisplayName, U.Reputation, PH.CreationDate
ORDER BY 
    P.CreationDate DESC
LIMIT 100;