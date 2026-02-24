
WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        U.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS ScoreRank
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId IN (1, 2) 
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(CASE 
            WHEN C.Name IS NOT NULL THEN C.Name 
            ELSE 'Undefined' 
        END, ', ') AS CloseReasons
    FROM
        PostHistory PH
    LEFT JOIN
        CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id 
    WHERE
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        PH.PostId
),
UserWithBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
PostEngagements AS (
    SELECT
        P.Id AS PostId,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        COALESCE(C.CommentCount, 0) AS CommentCount
    FROM
        Posts P
    LEFT JOIN (
        SELECT
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM
            Votes
        GROUP BY
            PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) C ON P.Id = C.PostId
)
SELECT
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.Score,
    RP.OwnerReputation,
    CP.CloseCount,
    CP.CloseReasons,
    U.BadgeCount,
    U.BadgeNames,
    PE.UpVotes,
    PE.DownVotes,
    PE.CommentCount
FROM
    RankedPosts RP
LEFT JOIN
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN
    UserWithBadges U ON RP.OwnerReputation = U.UserId
LEFT JOIN
    PostEngagements PE ON RP.PostId = PE.PostId
WHERE
    RP.ScoreRank = 1 
    AND RP.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
ORDER BY
    RP.CreationDate DESC;
