
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS AuthorName,
    COUNT(C.Id) AS CommentCount,
    COUNT(V.Id) AS VoteCount,
    P.Score,
    P.ViewCount,
    P.Tags
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName, P.Score, P.ViewCount, P.Tags
ORDER BY 
    P.CreationDate DESC
LIMIT 1000;
