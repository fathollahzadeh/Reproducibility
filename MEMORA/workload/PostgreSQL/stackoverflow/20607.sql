WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM
        Posts P
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND (P.ViewCount > 100 OR P.Score > 10)
),
ClosedPostHistory AS (
    SELECT
        PH.PostId,
        PH.Comment,
        MAX(PH.CreationDate) AS LatestCloseDate,
        STRING_AGG(CASE WHEN PHT.Name IS NOT NULL THEN PHT.Name ELSE 'Unknown' END, ', ') AS CloseReasons
    FROM
        PostHistory PH
    LEFT JOIN
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        PH.PostId, PH.Comment
),
FinalRankings AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.Rank,
        RP.UpVoteCount,
        RP.DownVoteCount,
        COALESCE(CPH.LatestCloseDate, NULL) AS LatestCloseDate,
        COALESCE(CPH.CloseReasons, 'Not Closed') AS CloseReasons
    FROM
        RankedPosts RP
    LEFT JOIN
        ClosedPostHistory CPH ON RP.PostId = CPH.PostId
)
SELECT
    FR.PostId,
    FR.Title,
    FR.Score,
    FR.ViewCount,
    FR.OwnerDisplayName,
    CASE 
        WHEN FR.LatestCloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    FR.CloseReasons,
    FR.UpVoteCount - FR.DownVoteCount AS NetVotes,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = FR.PostId) AS CommentCount
FROM
    FinalRankings FR
WHERE
    FR.Rank <= 5 
    AND (FR.UpVoteCount - FR.DownVoteCount) > 0 
ORDER BY
    FR.Score DESC, FR.ViewCount DESC;