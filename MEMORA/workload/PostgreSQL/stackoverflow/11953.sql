
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    COUNT(C.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    U.DisplayName AS AuthorDisplayName,
    U.Reputation AS AuthorReputation
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= '2023-01-01' 
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, U.Reputation
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
