
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopPosts AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate
    FROM Posts P
    WHERE P.PostTypeId = 1 
    ORDER BY P.Score DESC
    LIMIT 10
),
PostComments AS (
    SELECT
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM Comments C
    GROUP BY C.PostId
)
SELECT
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    COALESCE(PC.CommentCount, 0) AS CommentCount
FROM UserReputation U
JOIN TopPosts TP ON U.UserId = TP.OwnerUserId
LEFT JOIN PostComments PC ON TP.PostId = PC.PostId
ORDER BY U.Reputation DESC, TP.Score DESC;
