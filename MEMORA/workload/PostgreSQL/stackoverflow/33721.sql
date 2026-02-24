
WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate, 0 AS Level FROM Users WHERE Reputation > 1000
    UNION ALL
    SELECT u.Id, u.Reputation, u.CreationDate, ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    WHERE u.Reputation > 1000
),
TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score >= 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM Tags
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY Tags.TagName
),
UserBadges AS (
    SELECT U.Id AS UserId, 
           COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostScoreRank AS (
    SELECT P.Id AS PostId,
           RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM Posts P
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    PS.ScoreRank,
    TS.TagName,
    TS.PostCount,
    TS.PositivePosts,
    TS.NegativePosts
FROM Users U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostScoreRank PS ON U.Id = PS.PostId
LEFT JOIN TagStatistics TS ON EXISTS (
    SELECT 1 FROM Posts P 
    WHERE P.OwnerUserId = U.Id AND P.Id = PS.PostId
)
WHERE U.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
AND (U.Views IS NULL OR U.Views >= 100) 
GROUP BY U.DisplayName, U.Reputation, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges, PS.ScoreRank, TS.TagName, TS.PostCount, TS.PositivePosts, TS.NegativePosts
ORDER BY U.Reputation DESC, TS.PostCount DESC
LIMIT 50;
