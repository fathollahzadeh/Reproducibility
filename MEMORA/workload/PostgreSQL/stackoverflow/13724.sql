
SELECT 
    U.Reputation AS UserReputation,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.CreationDate AS PostCreationDate,
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
GROUP BY 
    U.Reputation, P.Score, P.ViewCount, P.CreationDate
ORDER BY 
    UserReputation DESC, PostScore DESC;
