SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    V.VoteTypeId,
    COUNT(V.Id) AS VoteCount,
    AVG(U.Reputation) AS AvgUserReputation
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2023-01-01'
GROUP BY 
    P.Id, U.DisplayName, P.Title, P.CreationDate, P.Score, P.ViewCount, V.VoteTypeId
ORDER BY 
    P.Score DESC, VoteCount DESC
LIMIT 100;