WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > (cast('2024-10-01' as date) - INTERVAL '1 year')
),
LatestVotes AS (
    SELECT 
        V.PostId,
        V.VoteTypeId,
        V.CreationDate,
        COUNT(*) OVER (PARTITION BY V.PostId, V.VoteTypeId) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate > (cast('2024-10-01' as date) - INTERVAL '30 days')
),
VoteSummary AS (
    SELECT 
        L.PostId,
        SUM(CASE WHEN L.VoteTypeId = 2 THEN L.VoteCount ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN L.VoteTypeId = 3 THEN L.VoteCount ELSE 0 END) AS DownVotes
    FROM 
        LatestVotes L
    GROUP BY 
        L.PostId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.OwnerDisplayName,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes,
    COALESCE(PHS.CloseCount, 0) AS CloseCount,
    COALESCE(PHS.ReopenCount, 0) AS ReopenCount,
    COALESCE(PHS.DeletionCount, 0) AS DeletionCount
FROM 
    RankedPosts RP
LEFT JOIN 
    VoteSummary VS ON RP.PostId = VS.PostId
LEFT JOIN 
    PostHistorySummary PHS ON RP.PostId = PHS.PostId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC NULLS LAST,
    RP.CreationDate ASC;