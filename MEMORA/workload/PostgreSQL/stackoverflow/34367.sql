WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM
        Posts P
    WHERE
        P.PostTypeId = 1  
),
UserVotes AS (
    SELECT
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM
        Votes V
    GROUP BY
        V.UserId
),
PostHistoryAggregates AS (
    SELECT
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM
        PostHistory PH
    GROUP BY
        PH.PostId
),
TopPosts AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerUserId,
        RP.Score,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(UV.UpVoteCount, 0) AS UpVotes,
        COALESCE(UV.DownVoteCount, 0) AS DownVotes,
        COALESCE(PHA.CloseCount, 0) AS CloseCount,
        COALESCE(PHA.ReopenCount, 0) AS ReopenCount
    FROM
        RankedPosts RP
    LEFT JOIN
        Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN
        UserVotes UV ON RP.OwnerUserId = UV.UserId
    LEFT JOIN
        PostHistoryAggregates PHA ON RP.PostId = PHA.PostId
    WHERE
        RP.PostRank = 1  
)
SELECT
    TP.Title,
    TP.CreationDate,
    TP.OwnerDisplayName,
    TP.UpVotes,
    TP.DownVotes,
    TP.CloseCount,
    TP.ReopenCount
FROM
    TopPosts TP
INNER JOIN
    Users U ON TP.OwnerUserId = U.Id
WHERE
    U.Reputation > 1000  
ORDER BY
    TP.Score DESC, TP.CloseCount DESC  
LIMIT 50;