WITH RECURSIVE UserBadges AS (
    SELECT U.Id AS UserId, 
           COUNT(B.Id) AS BadgeCount,
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT P.Id AS PostId, 
           P.OwnerUserId, 
           P.Title, 
           P.CreationDate, 
           P.Score,
           RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT U.DisplayName, 
       U.Reputation, 
       U.Location, 
       U.CreationDate, 
       UBad.BadgeCount, 
       UBad.GoldBadges, 
       UBad.SilverBadges, 
       UBad.BronzeBadges, 
       RPost.PostId,
       RPost.Title AS RecentPostTitle,
       RPost.Score AS RecentPostScore,
       RPost.CreationDate AS RecentPostDate
FROM Users U
JOIN UserBadges UBad ON U.Id = UBad.UserId
LEFT JOIN RecentPosts RPost ON U.Id = RPost.OwnerUserId AND RPost.PostRank = 1
WHERE U.Reputation > 1000
  AND U.Location IS NOT NULL
  AND (UBad.GoldBadges > 0 OR UBad.SilverBadges > 2)
ORDER BY U.Reputation DESC, RPost.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;