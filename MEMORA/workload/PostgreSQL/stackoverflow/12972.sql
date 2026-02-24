WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(C.Count, 0) AS CommentCount,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) A ON P.Id = A.ParentId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
), 
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.AnswerCount,
    PS.OwnerReputation,
    PHS.EditCount,
    PHS.LastEditDate,
    PHS.IsClosed,
    PHS.IsReopened
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryStats PHS ON PS.PostId = PHS.PostId
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;