WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount
    FROM Users U
    WHERE U.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownvoteCount
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    ORDER BY P.ViewCount DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.PostCount,
    U.CommentCount,
    U.BadgeCount,
    PP.PostId,
    PP.Title,
    PP.ViewCount,
    PP.Score,
    PP.AnswerCount,
    PP.UpvoteCount,
    PP.DownvoteCount
FROM UserStats U
CROSS JOIN PopularPosts PP
ORDER BY U.Reputation DESC, PP.ViewCount DESC;