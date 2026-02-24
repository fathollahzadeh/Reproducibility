
WITH RankedPosts AS (
    SELECT  
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),

PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, '; ') AS Comments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),

ClosedPosts AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),

FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.CreationDate,
        RP.OwnerDisplayName,
        COALESCE(PC.CommentCount, 0) AS TotalComments,
        COALESCE(PC.Comments, 'No comments') AS CommentSummaries,
        CP.LastClosedDate,
        CASE 
            WHEN CP.LastClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        RP.RankScore
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostComments PC ON RP.PostId = PC.PostId
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
)

SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    CreationDate,
    OwnerDisplayName,
    TotalComments,
    CommentSummaries,
    PostStatus,
    CASE 
        WHEN RankScore <= 5 THEN 'Top' 
        ELSE 'Others' 
    END AS RankCategory
FROM 
    FinalResults
WHERE 
    PostStatus = 'Open' AND
    TotalComments > 0
ORDER BY 
    Score DESC, 
    CreationDate DESC;
