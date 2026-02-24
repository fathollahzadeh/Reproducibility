
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        PH.CreationDate AS CloseDate,
        STRING_AGG(CONCAT(PH.UserDisplayName, ' ', PH.CreationDate), '; ') AS ClosedBy
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId, PH.Comment, PH.CreationDate
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE 
            WHEN V.VoteTypeId = 2 THEN 1 
            ELSE 0 END) AS UpVotes,
        SUM(CASE 
            WHEN V.VoteTypeId = 3 THEN 1 
            ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        V.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.Score,
    RP.OwnerName,
    RP.RankScore,
    RP.ViewRank,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(CP.CloseDate, NULL) AS CloseDate,
    COALESCE(CP.ClosedBy, 'N/A') AS ClosedBy,
    RV.VoteCount,
    RV.UpVotes,
    RV.DownVotes,
    CASE 
        WHEN RP.Score >= 0 THEN 'Popular'
        WHEN RP.Score < 0 AND RP.ViewCount > 100 THEN 'Controversial'
        ELSE 'Needs Attention' 
    END AS PostStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    RecentVotes RV ON RP.PostId = RV.PostId
WHERE 
    RP.RankScore <= 10
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
