WITH UserActivity AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           COUNT(P.Id) AS PostsCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
           SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount,
           MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.OwnerUserId,
           P.Score,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PopularTags AS (
    SELECT T.TagName,
           COUNT(P.Id) AS UsageCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    ORDER BY UsageCount DESC
    LIMIT 10
)
SELECT UA.UserId,
       UA.DisplayName,
       UA.PostsCount,
       UA.AnswersCount,
       UA.QuestionsCount,
       UA.BadgesCount,
       UA.LastPostDate,
       RP.Title AS RecentPostTitle,
       RP.CreationDate AS RecentPostDate,
       RP.Score AS RecentPostScore,
       PT.TagName AS PopularTag,
       PT.UsageCount AS TagUsageCount
FROM UserActivity UA
LEFT JOIN RecentPosts RP ON UA.UserId = RP.OwnerUserId AND RP.PostRank = 1
CROSS JOIN PopularTags PT
WHERE UA.PostsCount > 0
ORDER BY UA.PostsCount DESC, UA.LastPostDate DESC;