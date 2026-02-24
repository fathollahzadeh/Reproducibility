WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
PostHistoryCount AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    PS.VoteCount,
    PS.TotalComments,
    COALESCE(PHC.EditCount, 0) AS EditCount
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryCount PHC ON PS.PostId = PHC.PostId
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC
LIMIT 100;