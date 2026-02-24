
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.Reputation
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER(PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn,
        P.OwnerUserId
    FROM
        Posts P
    WHERE
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
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
PostVoteCounts AS (
    SELECT
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM
        Votes V
    GROUP BY
        V.PostId
)
SELECT
    U.Id AS UserId,
    U.DisplayName,
    UR.Reputation,
    UR.PostCount,
    UR.PositiveScoreCount,
    RP.PostId,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    COALESCE(CP.CloseCount, 0) AS TotalClosedPosts,
    PVC.UpVotes,
    PVC.DownVotes,
    CASE 
        WHEN UR.Reputation < 1000 THEN 'Low Reputation'
        WHEN UR.Reputation BETWEEN 1000 AND 5000 THEN 'Medium Reputation'
        ELSE 'High Reputation'
    END AS ReputationCategory
FROM
    Users U
JOIN
    UserReputation UR ON U.Id = UR.UserId
LEFT JOIN
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.rn = 1
LEFT JOIN
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN
    PostVoteCounts PVC ON RP.PostId = PVC.PostId
WHERE
    UR.PostCount > 0
ORDER BY
    UR.Reputation DESC, RP.CreationDate DESC
LIMIT 50;
