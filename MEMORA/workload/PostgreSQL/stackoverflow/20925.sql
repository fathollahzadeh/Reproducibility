
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS AuthorName
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
        AND P.PostTypeId = 1  
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.AuthorName,
        COALESCE(AV.UpVotes, 0) AS UpVotes,
        COALESCE(AV.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN COALESCE(AV.TotalVotes, 0) > 0 THEN 
                (COALESCE(AV.UpVotes, 0) * 1.0 / COALESCE(AV.TotalVotes, 1)) * 100
            ELSE 
                NULL 
        END AS UpVotePercentage
    FROM 
        RecentPosts RP
    LEFT JOIN 
        AggregatedVotes AV ON RP.PostId = AV.PostId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),
FinalResults AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        PD.AuthorName,
        PD.UpVotes,
        PD.DownVotes,
        PD.UpVotePercentage,
        CP.LastClosedDate,
        CP.CloseCount
    FROM 
        PostDetails PD
    LEFT JOIN 
        ClosedPosts CP ON PD.PostId = CP.PostId
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.Score,
    FR.ViewCount,
    FR.AuthorName,
    FR.UpVotes,
    FR.DownVotes,
    FR.UpVotePercentage,
    FR.LastClosedDate,
    FR.CloseCount,
    CASE 
        WHEN FR.CloseCount IS NULL THEN 'Not Closed'
        WHEN FR.LastClosedDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days' THEN 'Recently Closed'
        ELSE 'Older Closed'
    END AS CloseStatus
FROM 
    FinalResults FR
WHERE 
    FR.UpVotePercentage IS NOT NULL
ORDER BY 
    FR.UpVotePercentage DESC, 
    FR.ViewCount DESC
LIMIT 100;
