
WITH UserBadges AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(B.Id) AS BadgeCount, 
           SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, 
           SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT P.Id, P.Title, P.OwnerUserId, P.ViewCount, P.CreationDate, 
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS Rank
    FROM Posts P
    WHERE P.PostTypeId = 1 AND P.ViewCount > 1000
),
ActiveUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, U.LastAccessDate 
    FROM Users U
    WHERE U.LastAccessDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
PostComments AS (
    SELECT C.PostId, COUNT(C.Id) AS CommentCount
    FROM Comments C
    GROUP BY C.PostId
)
SELECT AU.DisplayName AS ActiveUser, UB.BadgeCount, UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges,
       PP.Title AS PopularPostTitle, PP.ViewCount, PP.CreationDate,
       COALESCE(PC.CommentCount, 0) AS TotalComments
FROM ActiveUsers AU
JOIN UserBadges UB ON AU.Id = UB.UserId
JOIN PopularPosts PP ON AU.Id = PP.OwnerUserId
LEFT JOIN PostComments PC ON PP.Id = PC.PostId
WHERE UB.BadgeCount > 5 AND PP.Rank = 1
ORDER BY AU.Reputation DESC, PP.ViewCount DESC;
