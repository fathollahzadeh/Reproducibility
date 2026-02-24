
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM
        Users U
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation
    FROM 
        UserReputation UR
    WHERE 
        UR.Reputation > (SELECT AVG(Reputation) FROM Users)
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        P.Title,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CloseHistoryRank
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
)

SELECT
    UR.DisplayName,
    UR.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CommentCount,
    CP.ClosedDate,
    CP.Comment AS CloseReasonComment
FROM
    TopUsers UR
LEFT JOIN
    RecentPosts RP ON UR.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN
    ClosedPosts CP ON RP.PostId = CP.PostId AND CP.CloseHistoryRank = 1
WHERE
    UR.Reputation > 1000
ORDER BY 
    UR.Reputation DESC
LIMIT 10;
