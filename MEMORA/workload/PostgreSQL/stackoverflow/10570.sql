WITH ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId
    FROM Posts P
    WHERE P.Score IS NOT NULL
    ORDER BY P.Score DESC
    LIMIT 10
)
SELECT 
    AU.UserId,
    AU.DisplayName,
    AU.Reputation,
    AU.PostCount,
    AU.CommentCount,
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.CreationDate
FROM ActiveUsers AU
JOIN TopPosts TP ON AU.UserId = TP.OwnerUserId
ORDER BY AU.Reputation DESC, AU.PostCount DESC;