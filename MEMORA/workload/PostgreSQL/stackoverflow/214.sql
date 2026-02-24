WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id
),
TopPostComments AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        UR.Reputation AS OwnerReputation,
        COALESCE(H.CloseReason, 'No reason') AS CloseReason
    FROM RecentPosts RP
    INNER JOIN Users U ON U.Id = RP.OwnerUserId
    LEFT JOIN (
        SELECT 
            PH.PostId,
            CT.Name AS CloseReason
        FROM PostHistory PH
        JOIN CloseReasonTypes CT ON PH.Comment::int = CT.Id
        WHERE PH.PostHistoryTypeId = 10
    ) H ON H.PostId = RP.PostId
    INNER JOIN UserReputation UR ON UR.UserId = RP.OwnerUserId
    WHERE RP.AnswerCount > 0
)
SELECT 
    TPC.PostId,
    TPC.Title,
    TPC.ViewCount,
    TPC.CommentCount,
    TPC.OwnerDisplayName,
    TPC.OwnerReputation,
    TPC.CloseReason
FROM TopPostComments TPC
WHERE TPC.OwnerReputation > (
    SELECT AVG(Reputation) FROM UserReputation
)
ORDER BY TPC.ViewCount DESC
LIMIT 10;