SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    P.FavoriteCount,
    V.VoteTypeId,
    COUNT(V.Id) AS VoteCount,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS TotalBadges
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2023-01-01' 
GROUP BY 
    P.Id, U.Id, V.VoteTypeId
ORDER BY 
    P.CreationDate DESC
LIMIT 100;