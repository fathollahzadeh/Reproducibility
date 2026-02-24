
SELECT 
    P.Id AS PostID,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    P.ViewCount,
    P.Score,
    COALESCE(COUNT(V.id), 0) AS TotalVotes,
    COALESCE((SELECT COUNT(C.id) FROM Comments C WHERE C.PostId = P.Id), 0) AS TotalComments,
    COALESCE((SELECT COUNT(B.id) FROM Badges B WHERE B.UserId = U.Id), 0) AS TotalBadges
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year' 
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName, U.Reputation, P.ViewCount, P.Score, U.Id
ORDER BY 
    P.CreationDate DESC;
