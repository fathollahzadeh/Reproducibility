
WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS Rank
    FROM
        Posts P
    WHERE
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
),
CloseReasons AS (
    SELECT
        PH.PostId,
        STRING_AGG(CRT.Name, ', ') AS CloseReasons
    FROM
        PostHistory PH
    JOIN
        CloseReasonTypes CRT ON CAST(PH.Comment AS int) = CRT.Id
    WHERE
        PH.PostHistoryTypeId = 10 
    GROUP BY
        PH.PostId
)
SELECT
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    U.DisplayName AS OwnerDisplayName,
    COALESCE(UR.GoldBadges, 0) AS GoldBadges,
    COALESCE(UR.SilverBadges, 0) AS SilverBadges,
    COALESCE(UR.BronzeBadges, 0) AS BronzeBadges,
    CR.CloseReasons,
    CASE
        WHEN RP.Rank > 10 THEN 'Not Featured'
        ELSE 'Featured'
    END AS PostRankStatus
FROM
    RankedPosts RP
LEFT JOIN
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN
    UserStats UR ON U.Id = UR.UserId
LEFT JOIN
    CloseReasons CR ON RP.PostId = CR.PostId
WHERE
    RP.PostId NOT IN (
        SELECT DISTINCT PL.RelatedPostId
        FROM PostLinks PL
        WHERE PL.LinkTypeId = 3 
    )
    AND (U.Reputation > 500 OR U.Location IS NOT NULL)
ORDER BY
    RP.Score DESC, RP.ViewCount DESC, RP.Title ASC;
