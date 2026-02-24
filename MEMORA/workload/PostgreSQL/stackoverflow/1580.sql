
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount,
        MAX(PH.CreationDate) AS LastActivity
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY PH.PostId
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RP.Title AS RecentPostTitle,
    RP.ViewCount,
    RP.Score,
    RP.AnswerCount,
    RP.CommentCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    COALESCE(PHC.HistoryCount, 0) AS PostHistoryCount,
    COALESCE(PHC.LastActivity, '1970-01-01') AS LastHistoryActivity,
    CASE 
        WHEN RU.Reputation > 1000 THEN 'High Reputation'
        WHEN RU.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM RankedUsers RU
LEFT JOIN RecentPosts RP ON RU.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN UserBadges UB ON RU.UserId = UB.UserId
LEFT JOIN PostHistoryCounts PHC ON RP.PostId = PHC.PostId
WHERE RU.ReputationRank <= 100
ORDER BY RU.Reputation DESC, RP.ViewCount DESC
LIMIT 50;
