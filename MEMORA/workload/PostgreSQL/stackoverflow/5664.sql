WITH RecentPosts AS (
    SELECT P.Id AS PostId, 
           P.Title,
           P.CreationDate,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate
),
PopularTags AS (
    SELECT T.TagName, 
           COUNT(*) AS UsageCount
    FROM Tags T
    JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY T.TagName
    ORDER BY UsageCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
    HAVING COUNT(B.Id) > 0
)
SELECT RP.PostId, 
       RP.Title, 
       RP.CreationDate, 
       RP.UpVotes, 
       RP.DownVotes, 
       RP.CommentCount, 
       PT.TagName, 
       UB.UserId, 
       UB.DisplayName AS UserWithBadges, 
       UB.BadgeCount
FROM RecentPosts RP
JOIN PopularTags PT ON RP.PostId IN (SELECT PostId FROM Posts WHERE Tags ILIKE '%' || PT.TagName || '%')
JOIN UserBadges UB ON RP.PostId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)
ORDER BY RP.UpVotes DESC, RP.CreationDate DESC
LIMIT 10;