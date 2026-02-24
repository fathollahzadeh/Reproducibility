
WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate AS PostCreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName,
        P.CreationDate, P.Score, P.ViewCount
),
PostStatistics AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.PostCreationDate,
        PD.Score,
        PD.ViewCount,
        PD.CommentCount,
        PD.HistoryCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        PostDetails PD
    LEFT JOIN 
        Votes V ON PD.PostId = V.PostId
    GROUP BY 
        PD.PostId, PD.Title, PD.OwnerDisplayName,
        PD.PostCreationDate, PD.Score, PD.ViewCount, 
        PD.CommentCount, PD.HistoryCount
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.OwnerDisplayName,
    PS.PostCreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.HistoryCount,
    PS.VoteCount
FROM 
    PostStatistics PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
