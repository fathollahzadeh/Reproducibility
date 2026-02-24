
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.Location,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.Reputation, U.CreationDate, U.Location
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.PostCount,
        U.BadgeCount,
        U.UpVotes,
        U.DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM UserStats U
),
TopPosts AS (
    SELECT 
        P.PostId,
        P.Title,
        P.ViewCount,
        P.CommentCount,
        P.UpVoteCount,
        P.DownVoteCount,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS Rank
    FROM PostStats P
)

SELECT 
    TU.UserId,
    TU.Reputation,
    TU.PostCount,
    TU.BadgeCount,
    TU.UpVotes,
    TU.DownVotes,
    TP.PostId,
    TP.Title AS PostTitle,
    TP.ViewCount AS PostViewCount,
    TP.CommentCount AS PostCommentCount,
    TP.UpVoteCount AS PostUpVoteCount,
    TP.DownVoteCount AS PostDownVoteCount
FROM TopUsers TU
JOIN TopPosts TP ON TU.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
WHERE TU.Rank <= 10 AND TP.Rank <= 10
ORDER BY TU.Rank, TP.Rank;
