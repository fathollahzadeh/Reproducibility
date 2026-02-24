
WITH RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM
        Posts P
    WHERE
        P.PostTypeId = 1 
        AND P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.Reputation
),
PostLinksCount AS (
    SELECT
        PL.PostId,
        COUNT(PL.RelatedPostId) AS LinksCount
    FROM
        PostLinks PL
    GROUP BY
        PL.PostId
),
ClosedPosts AS (
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
UserPostStats AS (
    SELECT
        U.DisplayName,
        U.Reputation,
        COALESCE(RP.PostId, -1) AS RecentPostId,
        P.Score,
        P.ViewCount,
        COALESCE(PLC.LinksCount, 0) AS LinksCount,
        COALESCE(CP.CloseCount, 0) AS CloseCount
    FROM
        Users U
    LEFT JOIN
        RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.rn = 1
    LEFT JOIN
        Posts P ON P.Id = RP.PostId
    LEFT JOIN
        PostLinksCount PLC ON P.Id = PLC.PostId
    LEFT JOIN
        ClosedPosts CP ON P.Id = CP.PostId
)
SELECT
    U.DisplayName,
    U.Reputation,
    R.RecentPostId AS PostId,
    P.Score,
    P.ViewCount,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(PLC.LinksCount, 0) AS LinksCount,
    CASE
        WHEN U.Reputation > 1000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    DENSE_RANK() OVER(ORDER BY U.Reputation DESC) AS ReputationRank
FROM
    UserPostStats R
JOIN
    Users U ON R.RecentPostId = U.Id
LEFT JOIN
    Posts P ON P.Id = R.RecentPostId
LEFT JOIN
    PostLinksCount PLC ON P.Id = PLC.PostId
LEFT JOIN
    ClosedPosts CP ON P.Id = CP.PostId
WHERE
    U.Reputation > 0
ORDER BY
    U.Reputation DESC;
