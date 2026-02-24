WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate,
        U.Reputation AS OwnerReputation,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = P.Id), 0) AS VoteCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.FavoriteCount,
        PS.CreationDate,
        PS.OwnerReputation,
        PS.VoteCount,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS Rank
    FROM PostStatistics PS
)
SELECT 
    U.UserId,
    U.Reputation AS UserReputation,
    COUNT(TP.PostId) AS TopPostCount,
    AVG(TP.Score) AS AvgPostScore,
    AVG(TP.ViewCount) AS AvgPostViewCount
FROM UserReputation U
JOIN TopPosts TP ON U.UserId = TP.OwnerReputation
WHERE TP.Rank <= 100
GROUP BY U.UserId, U.Reputation
ORDER BY U.Reputation DESC;