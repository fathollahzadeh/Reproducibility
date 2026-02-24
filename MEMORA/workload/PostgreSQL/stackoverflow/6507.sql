WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 1 ELSE 0 END) AS RecentPostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT TAG.TagName) AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN LATERAL UNNEST(string_to_array(P.Tags, '><')) AS TAG(TagName) ON TRUE
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount
),
TopUsers AS (
    SELECT 
        Us.UserId,
        Us.Reputation,
        Us.BadgeCount,
        Us.RecentPostCount,
        Us.UpvotesReceived,
        Us.DownvotesReceived,
        ROW_NUMBER() OVER (ORDER BY Us.Reputation DESC) AS Rank
    FROM UserStats Us
    WHERE Us.Reputation > 0
),
RankedPosts AS (
    SELECT 
        Pd.PostId,
        Pd.Title,
        Pd.Score,
        Pd.ViewCount,
        Pd.CommentCount,
        Pd.Tags,
        ROW_NUMBER() OVER (ORDER BY Pd.Score DESC, Pd.ViewCount DESC) AS PostRank
    FROM PostDetails Pd
)
SELECT 
    Tu.UserId,
    Tu.Reputation,
    Tu.BadgeCount,
    Tu.RecentPostCount,
    Tu.UpvotesReceived,
    Tu.DownvotesReceived,
    Rp.PostId,
    Rp.Title AS PostTitle,
    Rp.Score AS PostScore,
    Rp.ViewCount AS PostViewCount,
    Rp.CommentCount AS PostCommentCount,
    Rp.Tags AS PostTags
FROM TopUsers Tu
JOIN RankedPosts Rp ON Tu.UserId = Rp.PostId
WHERE Tu.Rank <= 10 AND Rp.PostRank <= 20
ORDER BY Tu.Reputation DESC, Rp.Score DESC;