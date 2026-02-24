WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) A ON P.Id = A.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
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
    PS.OwnerReputation,
    PH.CreationDate AS LastEditDate,
    PH.UserDisplayName AS LastEditor
FROM 
    PostSummary PS
LEFT JOIN 
    PostHistory PH ON PS.PostId = PH.PostId
WHERE 
    PH.PostHistoryTypeId IN (4, 5, 6) 
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;