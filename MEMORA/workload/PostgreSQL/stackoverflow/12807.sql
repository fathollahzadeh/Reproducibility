SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.ViewCount,
    U.DisplayName AS PostOwner,
    U.Reputation AS PostOwnerReputation,
    COALESCE(C.CommentCount, 0) AS TotalComments,
    COALESCE(V.VoteCount, 0) AS TotalVotes
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT 
         PostId, COUNT(*) AS CommentCount
     FROM 
         Comments 
     GROUP BY 
         PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT 
         PostId, COUNT(*) AS VoteCount
     FROM 
         Votes 
     GROUP BY 
         PostId) V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
ORDER BY 
    P.CreationDate DESC
LIMIT 100;