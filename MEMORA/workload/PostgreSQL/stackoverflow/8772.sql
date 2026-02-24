WITH RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score, P.ViewCount, P.AnswerCount,
           U.Reputation, U.DisplayName, P.Tags, P.LastActivityDate
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
      AND P.PostTypeId = 1
),
TopUsers AS (
    SELECT OwnerUserId, SUM(Score) AS TotalScore
    FROM RecentPosts
    GROUP BY OwnerUserId
    ORDER BY TotalScore DESC
    LIMIT 10
),
UserBadges AS (
    SELECT U.Id AS UserId, B.Name AS BadgeName
    FROM Users U
    JOIN Badges B ON U.Id = B.UserId
    WHERE B.Class = 1 OR B.Class = 2  
),
PostActivity AS (
    SELECT RP.Id AS PostId, RP.Title, RP.CreationDate, RP.ViewCount, RP.Score, RP.AnswerCount,
           U.DisplayName, UB.BadgeName
    FROM RecentPosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    WHERE RP.OwnerUserId IN (SELECT OwnerUserId FROM TopUsers)
    ORDER BY RP.Score DESC, RP.ViewCount DESC
)
SELECT PA.PostId, PA.Title, PA.CreationDate, PA.ViewCount, PA.Score, PA.AnswerCount, 
       PA.DisplayName, ARRAY_AGG(DISTINCT PA.BadgeName) AS Badges
FROM PostActivity PA
GROUP BY PA.PostId, PA.Title, PA.CreationDate, PA.ViewCount, PA.Score, PA.AnswerCount, PA.DisplayName
ORDER BY PA.Score DESC, PA.ViewCount DESC
LIMIT 20;