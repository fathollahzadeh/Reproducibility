
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    COUNT(C.Id) AS CommentCount,
    U.Reputation AS OwnerReputation,
    U.CreationDate AS UserCreationDate,
    U.LastAccessDate,
    U.Views AS UserViews,
    U.UpVotes,
    U.DownVotes,
    COALESCE(AVG(V.BountyAmount), 0) AS AvgBountyAmount
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, U.CreationDate, U.LastAccessDate, U.Views, U.UpVotes, U.DownVotes
ORDER BY 
    P.CreationDate DESC;
