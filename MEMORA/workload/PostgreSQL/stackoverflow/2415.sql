WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
ClosedPostCounts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),
PostVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    COALESCE(RP.RankScore, 0) AS RankScore,
    COALESCE(CPC.CloseCount, 0) AS CloseCount,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    (COALESCE(PV.UpVotes, 0) - COALESCE(PV.DownVotes, 0)) AS NetVotes
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPostCounts CPC ON RP.PostId = CPC.PostId
LEFT JOIN 
    PostVotes PV ON RP.PostId = PV.PostId
WHERE 
    RP.RankScore <= 3
ORDER BY 
    NetVotes DESC, RP.ViewCount DESC;