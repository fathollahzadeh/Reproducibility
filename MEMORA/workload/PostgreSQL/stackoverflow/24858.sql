
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS RankByReputation
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(PH.Id) AS EditCount
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN PostHistory PH ON PH.PostId = P.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId, P.CreationDate, P.LastActivityDate, P.AcceptedAnswerId
),
AggregatedPostStats AS (
    SELECT 
        RP.PostId,
        RP.OwnerUserId,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        AVG(
            CASE 
                WHEN RP.PostTypeId = 1 THEN EXTRACT(EPOCH FROM (RP.LastActivityDate - RP.CreationDate)) 
                ELSE NULL 
            END
        ) AS AvgTimeToResponse
    FROM RecentPosts RP
    LEFT JOIN Votes V ON V.PostId = RP.PostId
    GROUP BY RP.PostId, RP.OwnerUserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    AP.TotalVotes,
    AP.AvgTimeToResponse,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.BadgeNames, 'No badges') AS BadgeNames,
    RP.CommentCount,
    COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId IN (10, 11, 12)) AS CloseOpenCount
FROM RankedUsers RU
LEFT JOIN AggregatedPostStats AP ON AP.OwnerUserId = RU.UserId
LEFT JOIN UserBadges UB ON UB.UserId = RU.UserId
LEFT JOIN RecentPosts RP ON RP.OwnerUserId = RU.UserId
LEFT JOIN PostHistory PH ON PH.UserId = RU.UserId
WHERE RU.RankByReputation <= 10
GROUP BY RU.DisplayName, RU.Reputation, AP.TotalVotes, AP.AvgTimeToResponse, UB.BadgeCount, 
         UB.BadgeNames, RP.CommentCount
ORDER BY RU.Reputation DESC, AP.TotalVotes DESC;
