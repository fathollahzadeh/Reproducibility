
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostCloseReasons AS (
    SELECT
        PH.PostId,
        STRING_AGG(CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),
RecentPostsWithDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Author,
        RP.CreationDate,
        RP.Score,
        PS.UpVotes,
        PS.DownVotes,
        PCR.CloseReasons
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostVoteSummary PS ON RP.PostId = PS.PostId
    LEFT JOIN 
        PostCloseReasons PCR ON RP.PostId = PCR.PostId
    WHERE 
        RP.Rank <= 5 
)
SELECT 
    RPD.PostId,
    RPD.Title,
    RPD.Author,
    RPD.CreationDate,
    RPD.Score,
    COALESCE(RPD.UpVotes, 0) AS UpVotes,
    COALESCE(RPD.DownVotes, 0) AS DownVotes,
    COALESCE(RPD.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    RecentPostsWithDetails RPD
ORDER BY 
    RPD.CreationDate DESC;
