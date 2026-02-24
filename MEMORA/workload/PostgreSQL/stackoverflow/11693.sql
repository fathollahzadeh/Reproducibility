
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, U.DisplayName, P.Score, P.ViewCount
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.OwnerDisplayName,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
