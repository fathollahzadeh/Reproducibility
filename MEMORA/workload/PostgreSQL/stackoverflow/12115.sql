WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 END), 0) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    WHERE 
        P.CreationDate >= '2023-01-01'  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.BadgeCount
FROM 
    PostStats PS
ORDER BY 
    PS.ViewCount DESC, PS.Score DESC;