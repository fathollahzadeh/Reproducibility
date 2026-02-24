WITH PostTagCounts AS (
    SELECT P.Id AS PostId,
           COUNT(DISTINCT T.TagName) AS TagCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts P
    LEFT JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY P.Id
),
UserReputation AS (
    SELECT U.Id AS UserId,
           U.Reputation,
           P.OwnerUserId,
           COUNT(DISTINCT B.Id) AS BadgeCount,
           SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
           SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation, P.OwnerUserId
),
PostActivity AS (
    SELECT H.PostId,
           H.UserId,
           H.PostHistoryTypeId,
           COUNT(H.Id) AS ActivityCount
    FROM PostHistory H
    WHERE H.PostHistoryTypeId IN (10, 11, 12, 24) 
    GROUP BY H.PostId, H.UserId, H.PostHistoryTypeId
),
CombinedData AS (
    SELECT U.UserId,
           U.Reputation,
           U.BadgeCount,
           U.TotalViews,
           U.TotalScore,
           PTC.TagCount,
           COALESCE(PA.ActivityCount, 0) AS ActivityCount
    FROM UserReputation U
    LEFT JOIN PostTagCounts PTC ON U.UserId = PTC.PostId
    LEFT JOIN PostActivity PA ON U.UserId = PA.UserId
)
SELECT UserId,
       Reputation,
       BadgeCount,
       TotalViews,
       TotalScore,
       TagCount,
       ActivityCount,
       CASE WHEN TagCount > 5 THEN 'High Tag User'
            WHEN TagCount BETWEEN 3 AND 5 THEN 'Moderate Tag User'
            ELSE 'Low Tag User' END AS TagUserCategory
FROM CombinedData
ORDER BY TotalScore DESC, Reputation DESC;