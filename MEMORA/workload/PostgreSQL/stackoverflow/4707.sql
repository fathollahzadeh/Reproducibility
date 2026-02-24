
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH 
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.Location,
    UB.BadgeCount,
    UB.BadgeNames,
    RP.PostId,
    RP.Title,
    RP.CreationDate AS PostCreationDate,
    RP.Score AS PostScore,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    CP.LastClosedDate,
    ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
FROM Users U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN RecentPosts RP ON U.DisplayName = RP.OwnerDisplayName
LEFT JOIN ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    (U.Reputation > 1000 AND CP.CloseCount IS NULL) OR 
    (CP.CloseCount > 1)
ORDER BY U.Reputation DESC, RP.CreationDate DESC
LIMIT 50;
