
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount, P.Score
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.OwnerDisplayName,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.VoteCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    (EXTRACT(EPOCH FROM TIMESTAMP '2024-10-01 12:34:56' - PS.CreationDate) / 3600) AS HoursSinceCreation  
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC  
LIMIT 100;
