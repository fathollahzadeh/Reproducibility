WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.CreationDate, P.Score
),
ClosedPostDetails AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount,
        MIN(PH.CreationDate) AS FirstCloseDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11)
    GROUP BY PH.PostId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    TP.Title AS PostTitle,
    TP.CommentCount,
    CP.CloseVoteCount,
    CP.FirstCloseDate,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    CASE 
        WHEN CP.CloseVoteCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM UserReputation UR
JOIN TopPosts TP ON UR.UserId = TP.OwnerUserId 
LEFT JOIN ClosedPostDetails CP ON TP.PostId = CP.PostId
LEFT JOIN UserBadges UB ON UR.UserId = UB.UserId
WHERE UR.Reputation > 1000
  AND TP.UserPostRank <= 5
ORDER BY UR.Reputation DESC, TP.Score DESC;