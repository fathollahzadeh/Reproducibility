SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(C.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    AVG(V.BountyAmount) AS AverageBountyAmount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId IN (1, 2) 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC;