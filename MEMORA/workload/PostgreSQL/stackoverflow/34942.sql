WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(P.Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM Posts P
    WHERE P.PostTypeId = 1
    GROUP BY Tag
    ORDER BY TagCount DESC
    LIMIT 10
),
PostCommentsCount AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount
    FROM Comments C
    GROUP BY C.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    COALESCE(RP.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(RP.Score, 0) AS RecentPostScore,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    TT.Tag,
    TT.TagCount
FROM RecursiveUserStats U
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN PostCommentsCount PC ON RP.PostId = PC.PostId
LEFT JOIN TopTags TT ON TT.Tag = ANY(string_to_array(COALESCE(RP.Tags, ''), '><'))
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, TT.TagCount DESC NULLS LAST
LIMIT 100;