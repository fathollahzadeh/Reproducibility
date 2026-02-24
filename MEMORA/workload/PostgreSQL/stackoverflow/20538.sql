WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId IN (1, 2) 
),
PostMetrics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.UpVotes,
        RP.DownVotes,
        CASE 
            WHEN RP.RankScore = 1 THEN 'Top Post'
            WHEN RP.RankScore IS NULL THEN 'No Posts'
            ELSE 'Other Posts'
        END AS RankCategory,
        COALESCE(U.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Users U ON RP.OwnerUserId = U.Id
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        PH.Comment,
        PH.CreationDate,
        PHT.Name AS HistoryType
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Id IN (10, 11, 12) 
)
SELECT 
    PM.*,
    COUNT(PHI.Comment) AS HistoryCount,
    STRING_AGG(PHI.Comment, '; ') FILTER (WHERE PHI.Comment IS NOT NULL) AS HistoryComments
FROM 
    PostMetrics PM
LEFT JOIN 
    PostHistoryInfo PHI ON PM.PostId = PHI.PostId
GROUP BY 
    PM.PostId, PM.Title, PM.CreationDate, PM.Score, PM.ViewCount, PM.UpVotes, PM.DownVotes, PM.RankCategory, PM.OwnerDisplayName
HAVING 
    SUM(PM.UpVotes) - SUM(PM.DownVotes) > 0 
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC
LIMIT 100;