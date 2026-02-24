
WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation,
        DENSE_RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank,
        P.OwnerUserId
    FROM
        Posts P
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),
PostVoteSummary AS (
    SELECT
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM
        Votes V
    GROUP BY
        V.PostId
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT CT.Name, ', ') AS CloseReasons
    FROM
        PostHistory PH
    JOIN
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        PH.PostId
)
SELECT
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    U.UserId,
    U.BadgeCount,
    U.HighestBadgeClass,
    PVS.UpVotes,
    PVS.DownVotes,
    PVS.TotalVotes,
    CPL.LastClosedDate,
    CPL.CloseReasons,
    CASE 
        WHEN CPL.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM
    RankedPosts RP
LEFT JOIN
    UserBadges U ON RP.OwnerUserId = U.UserId
LEFT JOIN
    PostVoteSummary PVS ON RP.PostId = PVS.PostId
LEFT JOIN
    ClosedPosts CPL ON RP.PostId = CPL.PostId
WHERE
    RP.Rank <= 3 
    AND (U.BadgeCount IS NULL OR U.BadgeCount BETWEEN 1 AND 5) 
ORDER BY
    RP.PostId;
