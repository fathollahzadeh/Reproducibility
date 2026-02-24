
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY P.Id, P.OwnerUserId, P.Title, P.CreationDate, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.CommentCount,
        UR.DisplayName AS OwnerName,
        UR.ReputationRank
    FROM RecentPosts RP
    INNER JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
    WHERE UR.ReputationRank <= 10
)
SELECT 
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.CommentCount,
    TP.OwnerName,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId = TP.PostId AND V.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId = TP.PostId AND V.VoteTypeId = 3) AS Downvotes
FROM TopPosts TP
ORDER BY TP.Score DESC, TP.ViewCount DESC
LIMIT 10;
