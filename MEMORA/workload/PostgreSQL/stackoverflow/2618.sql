WITH UserReputation AS (
    SELECT Id, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostStats AS (
    SELECT P.Id AS PostId, 
           P.OwnerUserId, 
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           COUNT(DISTINCT PV.Id) AS VoteCount,
           AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes PV ON P.Id = PV.PostId AND PV.VoteTypeId = 2 
    GROUP BY P.Id, P.OwnerUserId
),
RecentCloseHistory AS (
    SELECT PH.PostId, 
           HT.Name AS HistoryType, 
           PH.CreationDate
    FROM PostHistory PH
    JOIN PostHistoryTypes HT ON PH.PostHistoryTypeId = HT.Id
    WHERE HT.Name IN ('Post Closed', 'Post Reopened')
    AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadgeStats AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT U.DisplayName,
       U.Reputation,
       UR.Rank,
       PS.PostId,
       PS.CommentCount,
       PS.VoteCount,
       PS.AverageScore,
       COALESCE(RCH.RecentActivity, 'No Recent Activity') AS RecentActivity,
       UBS.GoldBadges,
       UBS.SilverBadges,
       UBS.BronzeBadges
FROM Users U
JOIN UserReputation UR ON U.Id = UR.Id
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN (
    SELECT PostId, 
           STRING_AGG(HistoryType, ', ') AS RecentActivity
    FROM RecentCloseHistory
    GROUP BY PostId
) RCH ON PS.PostId = RCH.PostId
LEFT JOIN UserBadgeStats UBS ON U.Id = UBS.UserId
WHERE U.Reputation > 1000
AND (U.Location IS NOT NULL OR U.WebsiteUrl IS NOT NULL)
ORDER BY U.Reputation DESC, PS.AverageScore DESC
LIMIT 100;