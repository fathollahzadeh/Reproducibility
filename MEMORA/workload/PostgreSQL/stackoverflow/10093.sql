SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.ViewCount,
    P.Score,
    COUNT(CM.Id) AS CommentCount,
    SUM(V.BountyAmount) AS TotalBounty,
    U.Reputation AS UserReputation,
    U.CreationDate AS UserCreationDate,
    U.DisplayName AS UserDisplayName
FROM 
    Posts P
LEFT JOIN 
    Comments CM ON P.Id = CM.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.Reputation, U.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;