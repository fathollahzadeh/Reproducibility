WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY PT.Name ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    INNER JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
PostDetails AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Body,
        TP.CreationDate,
        TP.Score,
        TP.ViewCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        TopPosts TP
    LEFT JOIN 
        Comments C ON TP.PostId = C.PostId
    LEFT JOIN 
        Votes V ON TP.PostId = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        TP.PostId, TP.Title, TP.Body, TP.CreationDate, TP.Score, TP.ViewCount
),
PostHistoryChanges AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PHT.Name AS PostHistoryType,
        PH.UserDisplayName,
        PH.Comment,
        PH.Text
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.Body,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.CommentCount,
    PD.TotalBounty,
    STRING_AGG(DISTINCT PHC.PostHistoryType, '; ') AS RecentChanges
FROM 
    PostDetails PD
LEFT JOIN 
    PostHistoryChanges PHC ON PD.PostId = PHC.PostId
GROUP BY 
    PD.PostId, PD.Title, PD.Body, PD.CreationDate, PD.Score, PD.ViewCount, PD.CommentCount, PD.TotalBounty
ORDER BY 
    PD.Score DESC,
    PD.ViewCount DESC;