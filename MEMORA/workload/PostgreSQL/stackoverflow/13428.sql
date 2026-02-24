WITH PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS RevisionCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    PVS.PostId,
    PVS.Title,
    PVS.Score,
    PVS.CreationDate,
    PVS.UpVoteCount,
    PVS.DownVoteCount,
    PVS.CommentCount,
    PHS.RevisionCount,
    PHS.LastEditDate
FROM 
    PostVoteStats PVS
LEFT JOIN 
    PostHistoryStats PHS ON PVS.PostId = PHS.PostId
ORDER BY 
    PVS.Score DESC, PVS.UpVoteCount DESC;