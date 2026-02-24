WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS TagName
    ) T ON TRUE
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate
),
PopularBadgedUsers AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.BadgeCount,
        AB.PostId,
        AB.Title,
        AB.CommentCount,
        AB.UpvoteCount,
        AB.DownvoteCount,
        AB.Tags
    FROM UserBadges UB
    JOIN ActivePosts AB ON UB.BadgeCount > 2 
    ORDER BY UB.BadgeCount DESC, AB.UpvoteCount DESC
    LIMIT 10
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    PostId,
    Title AS PostTitle,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    Tags
FROM PopularBadgedUsers
ORDER BY BadgeCount DESC, UpvoteCount DESC;