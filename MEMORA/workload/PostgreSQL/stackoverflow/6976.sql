WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount, P.Score
),
FilteredRankedPosts AS (
    SELECT 
        RP.*,
        CASE WHEN RP.CommentCount > 0 THEN 'Has Comments' ELSE 'No Comments' END AS CommentStatus
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 10
)
SELECT 
    FRP.PostId,
    FRP.Title,
    FRP.CreationDate,
    FRP.OwnerDisplayName,
    FRP.ViewCount,
    FRP.Score,
    FRP.CommentCount,
    FRP.AnswerCount,
    FRP.CommentStatus
FROM 
    FilteredRankedPosts FRP
ORDER BY 
    FRP.Score DESC, FRP.CreationDate DESC;