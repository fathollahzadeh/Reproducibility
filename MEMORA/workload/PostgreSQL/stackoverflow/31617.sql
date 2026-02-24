WITH RecursivePost AS (
    SELECT P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, P.AcceptedAnswerId, 
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS rn
    FROM Posts P
    WHERE P.PostTypeId = 1 
),
TopUsers AS (
    SELECT U.Id AS UserId, U.DisplayName, U.Reputation, 
           COUNT(P.Id) AS QuestionCount, 
           SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    GROUP BY U.Id, U.DisplayName, U.Reputation
    HAVING COUNT(P.Id) > 5 
),
UserBadges AS (
    SELECT U.Id AS UserId, 
           STRING_AGG(B.Name, ', ') AS BadgeNames,
           COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
ClosedAndEditedPosts AS (
    SELECT P.Id AS PostId, 
           PHP.PostHistoryTypeId,
           COUNT(PHP.Id) AS HistoryCount,
           MAX(P.LastEditDate) AS LastEditDate
    FROM Posts P
    JOIN PostHistory PHP ON P.Id = PHP.PostId
    WHERE PHP.PostHistoryTypeId IN (10, 12) 
    GROUP BY P.Id, PHP.PostHistoryTypeId
)
SELECT U.DisplayName, 
       U.Reputation,
       T.BadgeNames,
       T.BadgeCount,
       COUNT(PC.PostId) AS ClosedPostCount,
       AVG(COALESCE(P.Score, 0)) AS AvgScore, 
       SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
FROM TopUsers U
LEFT JOIN UserBadges T ON U.UserId = T.UserId
LEFT JOIN ClosedAndEditedPosts PC ON U.UserId = PC.PostId
LEFT JOIN Posts P ON U.UserId = P.OwnerUserId
WHERE U.Reputation > 1000 
GROUP BY U.DisplayName, U.Reputation, T.BadgeNames, T.BadgeCount
HAVING COUNT(*) >= 10 
ORDER BY TotalViews DESC, AvgScore DESC
LIMIT 25;