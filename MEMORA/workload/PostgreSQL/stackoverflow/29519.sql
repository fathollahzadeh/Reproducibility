WITH PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        COALESCE(P.FavoriteCount, 0) AS FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (1, 2, 4, 5) THEN 1 END) AS EditCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2020-01-01' 
        AND P.Title IS NOT NULL
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, AnswerCount, CommentCount, FavoriteCount, U.DisplayName
),
PostStatistics AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.CreationDate,
        PA.ViewCount,
        PA.AnswerCount,
        PA.CommentCount,
        PA.FavoriteCount,
        PA.OwnerDisplayName,
        PA.CloseCount,
        PA.ReopenCount,
        PA.EditCount,
        (PA.ViewCount + PA.FavoriteCount + PA.AnswerCount + PA.CommentCount) AS EngagementScore,
        ROW_NUMBER() OVER (ORDER BY (PA.ViewCount + PA.FavoriteCount + PA.AnswerCount + PA.CommentCount) DESC) AS Rank
    FROM 
        PostActivity PA
)
SELECT 
    PS.Rank,
    PS.PostId,
    PS.Title,
    PS.OwnerDisplayName,
    PS.CreationDate,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.CloseCount,
    PS.ReopenCount,
    PS.EditCount,
    PS.EngagementScore
FROM 
    PostStatistics PS
WHERE 
    PS.Rank <= 10
ORDER BY 
    PS.EngagementScore DESC;
