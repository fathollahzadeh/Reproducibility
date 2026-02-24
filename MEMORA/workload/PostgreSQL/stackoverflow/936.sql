
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        COALESCE(C.Count, 0) AS CommentCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Count
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) B ON P.OwnerUserId = B.UserId
),
TopPosts AS (
    SELECT 
        PS.*,
        R.ReputationRank
    FROM PostStats PS
    JOIN UserReputation R ON PS.OwnerUserId = R.UserId
    WHERE PS.Score > 0
)
SELECT 
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.UpVotes,
    TP.DownVotes,
    TP.CommentCount,
    TP.ReputationRank,
    U.DisplayName
FROM TopPosts TP
JOIN Users U ON TP.OwnerUserId = U.Id
WHERE TP.ReputationRank <= 10
ORDER BY TP.Score DESC, TP.CommentCount DESC
LIMIT 50;
