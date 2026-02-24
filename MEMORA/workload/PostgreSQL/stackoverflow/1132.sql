
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
CloseReasonSummary AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseReasonCount,
        STRING_AGG(CR.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON CAST(PH.Comment AS INTEGER) = CR.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerName,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes,
    COALESCE(PVS.TotalVotes, 0) AS TotalVotes,
    COALESCE(CRS.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(CRS.CloseReasons, 'No close reasons') AS CloseReasons,
    CASE 
        WHEN RP.PostRank = 1 THEN 'Top Post'
        WHEN RP.PostRank <= 5 THEN 'High Performer'
        ELSE 'Regular Post' 
    END AS PerformanceCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    PostVoteSummary PVS ON RP.PostId = PVS.PostId
LEFT JOIN 
    CloseReasonSummary CRS ON RP.PostId = CRS.PostId
WHERE 
    RP.PostRank <= 10
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;
