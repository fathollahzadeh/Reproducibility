SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    COALESCE(V.VoteCount, 0) AS VoteCount,
    COALESCE(C.CommentCount, 0) AS CommentCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) V ON P.Id = V.PostId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) C ON P.Id = C.PostId
ORDER BY 
    U.Reputation DESC, 
    P.CreationDate DESC;