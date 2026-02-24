
WITH RecursiveCommentCounts AS (
    SELECT PostId, COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY PostId
),
UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, COALESCE(UB.BadgeCount, 0) AS TotalBadges
    FROM Users U
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
    WHERE U.Reputation > 1000
    ORDER BY TotalBadges DESC, U.Reputation DESC
    LIMIT 10
),
PostAnalytics AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, COALESCE(CC.TotalComments, 0) AS CommentCount
    FROM Posts P
    LEFT JOIN RecursiveCommentCounts CC ON P.Id = CC.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    AND P.PostTypeId = 1
),
PostHistoryAnalytics AS (
    SELECT PH.PostId, PH.UserId, PH.CreationDate,
           P.Title AS PostTitle,
           P.Body AS PostBody, 
           PH.Comment,
           RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentActivity
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (10, 11, 12)
),
FinalAnalytics AS (
    SELECT PA.Id AS PostId, 
           PA.Title AS PostTitle, 
           PA.ViewCount, 
           PA.Score, 
           PA.CommentCount, 
           U.DisplayName AS TopUser, 
           U.TotalBadges AS UserBadges
    FROM PostAnalytics PA
    LEFT JOIN TopUsers U ON PA.Score = (SELECT MAX(Score) FROM PostAnalytics WHERE Score IS NOT NULL)
)

SELECT 
    F.PostId, 
    F.PostTitle, 
    F.ViewCount,
    F.Score,
    F.CommentCount,
    F.TopUser,
    F.UserBadges
FROM FinalAnalytics F
ORDER BY F.Score DESC, 
         F.ViewCount DESC
LIMIT 20;
