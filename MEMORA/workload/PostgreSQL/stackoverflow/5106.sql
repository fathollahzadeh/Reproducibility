
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.Views,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    JOIN UserBadges UB ON U.Id = UB.UserId
    WHERE U.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 DAY'
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.OwnerUserId
    HAVING COUNT(V.Id) > 10
),
UserTopPosts AS (
    SELECT 
        U.DisplayName,
        PP.Title,
        PP.Score,
        PP.VoteCount,
        RANK() OVER (PARTITION BY U.Id ORDER BY PP.VoteCount DESC) AS PostRank
    FROM TopUsers U
    JOIN PopularPosts PP ON U.Id = PP.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    P.Title AS TopPostTitle,
    P.Score AS PostScore,
    P.VoteCount AS PostVoteCount
FROM TopUsers U
JOIN UserTopPosts P ON U.DisplayName = P.DisplayName
WHERE P.PostRank = 1
ORDER BY U.Reputation DESC;
