
WITH UserBadges AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date AS BadgeDate,
        COUNT(*) OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeCount
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS PostRank
    FROM
        Posts P
    INNER JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TopTags AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY
        T.TagName
),
PostAnalytics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosureCount,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS UpvotedUsernames
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN
        Users U ON V.UserId = U.Id
    WHERE
        P.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY
        P.Id
)
SELECT
    UB.UserId,
    UB.DisplayName,
    UB.BadgeName,
    UB.Class,
    RP.PostId,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    RP.Score AS RecentPostScore,
    RP.ViewCount AS RecentPostViewCount,
    (SELECT STRING_AGG(T.TagName, ', ')
     FROM TopTags T WHERE T.TagRank <= 5) AS TopTags,
    PA.CommentCount,
    PA.UpVotes,
    PA.DownVotes,
    PA.ClosureCount,
    PA.UpvotedUsernames
FROM
    UserBadges UB
FULL OUTER JOIN
    RecentPosts RP ON UB.DisplayName = RP.OwnerDisplayName
LEFT JOIN 
    PostAnalytics PA ON RP.PostId = PA.PostId
WHERE
    UB.BadgeCount IS NULL OR UB.BadgeCount > 5
ORDER BY
    UB.UserId, RP.CreationDate DESC;
