
WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS BadgeCount, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, 
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT P.OwnerUserId, COUNT(C.Id) AS CommentCount, 
           SUM(P.Score) AS TotalScore, 
           COUNT(DISTINCT P.Id) AS PostCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
CombinedData AS (
    SELECT U.Id AS UserId, U.DisplayName, 
           COALESCE(UB.BadgeCount, 0) AS BadgeCount, 
           COALESCE(UB.GoldBadges, 0) AS GoldBadges, 
           COALESCE(UB.SilverBadges, 0) AS SilverBadges, 
           COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
           COALESCE(PS.CommentCount, 0) AS CommentCount, 
           COALESCE(PS.TotalScore, 0) AS TotalScore, 
           COALESCE(PS.PostCount, 0) AS PostCount
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT UserId, DisplayName, BadgeCount, GoldBadges, SilverBadges, 
       BronzeBadges, CommentCount, TotalScore, PostCount
FROM CombinedData
WHERE BadgeCount > 0 AND PostCount > 5
ORDER BY TotalScore DESC, BadgeCount DESC
LIMIT 10;
