WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(Id) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostScoreStatistics AS (
    SELECT OwnerUserId, 
           AVG(Score) AS AvgScore, 
           SUM(ViewCount) AS TotalViews, 
           COUNT(*) AS PostCount
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY OwnerUserId
),
UserReputation AS (
    SELECT U.Id AS UserId, 
           U.Reputation, 
           U.DisplayName,
           COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
           COALESCE(PSS.AvgScore, 0) AS AvgPostScore,
           COALESCE(PSS.TotalViews, 0) AS TotalPostViews,
           COALESCE(PSS.PostCount, 0) AS TotalPosts
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN PostScoreStatistics PSS ON U.Id = PSS.OwnerUserId
)
SELECT U.DisplayName, 
       U.Reputation, 
       U.BadgeCount, 
       U.AvgPostScore,
       U.TotalPostViews, 
       U.TotalPosts 
FROM UserReputation U
WHERE U.Reputation > 1000 
ORDER BY U.AvgPostScore DESC, U.TotalPosts DESC
LIMIT 20;