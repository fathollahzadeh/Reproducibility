WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldCount, 
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
), PopularPosts AS (
    SELECT OwnerUserId, COUNT(*) AS PostsCreated, SUM(ViewCount) AS TotalViews
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY OwnerUserId
), UserEngagement AS (
    SELECT U.Id AS UserId, U.DisplayName, COALESCE(UB.BadgeCount, 0) AS BadgeCount,
           COALESCE(PP.PostsCreated, 0) AS PostsCreated, COALESCE(PP.TotalViews, 0) AS TotalViews
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PopularPosts PP ON U.Id = PP.OwnerUserId
), RankedUsers AS (
    SELECT UserId, DisplayName, BadgeCount, PostsCreated, TotalViews,
           ROW_NUMBER() OVER (ORDER BY TotalViews DESC, PostsCreated DESC, BadgeCount DESC) AS Rank
    FROM UserEngagement
)
SELECT Rank, UserId, DisplayName, BadgeCount, PostsCreated, TotalViews
FROM RankedUsers
WHERE Rank <= 10
ORDER BY Rank;