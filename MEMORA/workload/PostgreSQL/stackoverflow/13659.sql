
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(DISTINCT V.Id) AS VoteCount,
    COUNT(DISTINCT BH.Id) AS HistoryChangeCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostHistory BH ON P.Id = BH.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate > DATE '2020-01-01' 
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
