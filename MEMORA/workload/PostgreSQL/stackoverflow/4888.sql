WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 1000
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.OwnerUserId, P.CreationDate, P.Title, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        UR.UserId,
        UR.DisplayName,
        UR.ReputationRank
    FROM RecentPosts RP
    JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
    WHERE RP.Score > 10
),
PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY PH.PostId
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.DisplayName,
    TP.ReputationRank,
    PH.EditCount,
    PH.LastEditedDate,
    CASE 
        WHEN PH.EditCount IS NULL THEN 'No Edits'
        ELSE 'Edited'
    END AS EditStatus
FROM TopPosts TP
LEFT JOIN PostHistories PH ON TP.PostId = PH.PostId
WHERE TP.ReputationRank <= 10 
ORDER BY TP.Score DESC, TP.ViewCount DESC;