
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 END) AS HistoryCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId IS NOT NULL
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.CommentCount,
        PS.UpvoteCount,
        PS.DownvoteCount,
        PS.HistoryCount,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.CommentCount DESC) AS Rank
    FROM PostStats PS
)
SELECT 
    U.DisplayName,
    UReputation.Reputation,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.CommentCount,
    TP.UpvoteCount,
    TP.DownvoteCount,
    TP.HistoryCount
FROM TopPosts TP
JOIN Users U ON U.Id = (
    SELECT OwnerUserId 
    FROM Posts 
    WHERE Id = TP.PostId
)
JOIN UserReputation UReputation ON U.Id = UReputation.UserId
WHERE TP.Rank <= 10
ORDER BY UReputation.Reputation DESC, TP.Score DESC;
