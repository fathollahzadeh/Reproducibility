WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        T.TagName,
        PH.CreationDate AS HistoryCreationDate,
        PH.PostHistoryTypeId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        Tags T ON T.Id = P.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
)

SELECT 
    PS.OwnerDisplayName,
    PS.Title,
    PS.CreationDate,
    PS.LastActivityDate,
    PS.Score,
    PS.AnswerCount,
    PS.ViewCount,
    PS.CommentCount,
    PS.TagName,
    COUNT(PH.PostHistoryTypeId) AS HistoryCount
FROM 
    PostStats PS
LEFT JOIN 
    PostHistory PH ON PS.PostId = PH.PostId
GROUP BY 
    PS.OwnerDisplayName, PS.Title, PS.CreationDate, PS.LastActivityDate, PS.Score, PS.AnswerCount, PS.ViewCount, PS.CommentCount, PS.TagName
ORDER BY 
    PS.LastActivityDate DESC
LIMIT 100;