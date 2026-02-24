
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(PH.Id) AS TotalHistoryChanges
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        RP.OwnerName,
        PHD.HistoryTypes,
        PHD.TotalHistoryChanges
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistoryDetails PHD ON RP.PostId = PHD.PostId
    WHERE 
        RP.PostRank <= 10
)
SELECT 
    TP.*,
    CASE 
        WHEN TP.TotalHistoryChanges > 5 THEN 'High'
        WHEN TP.TotalHistoryChanges BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS HistoryChangeLevel,
    CASE 
        WHEN TP.Score IS NULL THEN 'No Score'
        ELSE 'Has Score'
    END AS ScoreStatus
FROM 
    TopPosts TP
WHERE 
    TP.ViewCount > 100 
ORDER BY 
    TP.Score DESC;
