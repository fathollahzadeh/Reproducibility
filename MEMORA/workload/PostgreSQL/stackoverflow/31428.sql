WITH RecursiveUserScores AS (
    SELECT U.Id AS UserId, U.Reputation, U.DisplayName, U.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS RowNum
    FROM Users U
), 
UserBadges AS (
    SELECT B.UserId, COUNT(*) AS BadgeCount, 
           STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId, 
           P.ViewCount, P.Tags,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PopularTags AS (
    SELECT TRIM(unnest(string_to_array(P.Tags, ' '))) AS TagName,
           COUNT(*) AS TagCount
    FROM Posts P
    WHERE P.Tags IS NOT NULL
    GROUP BY TRIM(unnest(string_to_array(P.Tags, ' ')))
    ORDER BY TagCount DESC
    LIMIT 10
)
SELECT U.DisplayName, U.Reputation, 
       COALESCE(UB.BadgeCount, 0) AS TotalBadges, 
       COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
       RP.Title AS LastPostTitle, RP.Score AS LastPostScore, 
       RP.ViewCount AS LastPostViews,
       PT.TagName AS PopularTag, PT.TagCount
FROM RecursiveUserScores U
LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId AND RP.PostRank = 1
LEFT JOIN PopularTags PT ON PT.TagName = ANY(string_to_array(RP.Tags, ' '))
WHERE U.Reputation > 1000
  AND U.CreationDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY U.Reputation DESC, LastPostScore DESC
LIMIT 50;