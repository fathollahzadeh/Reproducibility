
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P 
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS integer) = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
),
TopClosedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        COALESCE(CT.CloseReason, 'Not Closed') AS CloseReason
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CT ON RP.PostId = CT.PostId AND CT.CloseRank = 1
    WHERE 
        RP.Rank <= 10
)
SELECT 
    TCP.Title,
    TCP.OwnerDisplayName,
    COALESCE(TCP.CloseReason, 'Active') AS Status,
    RP.ViewCount,
    RP.UpVoteCount,
    RP.DownVoteCount
FROM 
    TopClosedPosts TCP
JOIN 
    RankedPosts RP ON TCP.PostId = RP.PostId
ORDER BY 
    RP.Score DESC, TCP.Title;
