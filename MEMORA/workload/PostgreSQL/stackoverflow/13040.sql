
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.VoteCount,
    P.OwnerDisplayName,
    U.Reputation,
    U.CreationDate AS UserCreationDate,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = P.OwnerUserId) AS BadgeCount
FROM 
    PostStatistics PS
JOIN 
    Posts P ON PS.PostId = P.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
ORDER BY 
    PS.Score DESC
FETCH FIRST 100 ROWS ONLY;
