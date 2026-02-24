
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS NumberOfComments,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(DISTINCT PH.Id) AS HistoryCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.CreationDate >= DATE '2023-01-01' 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.AnswerCount, P.CommentCount, P.Score, 
    U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC;
