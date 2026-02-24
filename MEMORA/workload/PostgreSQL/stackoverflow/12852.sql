
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount,
        U.DisplayName AS Owner,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, U.DisplayName, U.Reputation
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount
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
    PS.AnswerCount,
    PS.CommentCount,
    PS.Owner,
    PS.OwnerReputation,
    COALESCE(PHC.HistoryCount, 0) AS HistoryActionCount
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryCounts PHC ON PS.PostId = PHC.PostId
ORDER BY 
    PS.ViewCount DESC
LIMIT 100;
