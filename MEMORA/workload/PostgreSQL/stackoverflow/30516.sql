
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND P.PostTypeId = 1 
),
HighScorePosts AS (
    SELECT 
        PostId,
        Title,
        OwnerUserId,
        OwnerName,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 
),
PostVoteStats AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
ClosureReasons AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CAST(CRT.Name AS TEXT), ', ') AS ClosureReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::INTEGER = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
)
SELECT 
    HSP.PostId,
    HSP.Title,
    HSP.OwnerName,
    HSP.ViewCount,
    HSP.Score,
    COALESCE(PVS.UpVotes, 0) AS UpVotes,
    COALESCE(PVS.DownVotes, 0) AS DownVotes,
    COALESCE(CR.CloseCount, 0) AS ClosedCount,
    COALESCE(CR.ClosureReasons, 'No close reasons') AS ClosureReasons
FROM 
    HighScorePosts HSP
LEFT JOIN 
    PostVoteStats PVS ON HSP.PostId = PVS.PostId
LEFT JOIN 
    ClosureReasons CR ON HSP.PostId = CR.PostId
ORDER BY 
    HSP.Score DESC, HSP.ViewCount DESC;
