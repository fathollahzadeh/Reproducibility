
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 0
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(C.ID) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.Score, P.CreationDate, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId, PH.PostHistoryTypeId
),
PostMetrics AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Score,
        TP.CommentCount,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        U.DisplayName AS Owner,
        U.Reputation AS OwnerReputation,
        U.ReputationRank AS OwnerRank
    FROM TopPosts TP
    JOIN UserReputation U ON TP.OwnerUserId = U.UserId
    LEFT JOIN ClosedPosts CP ON TP.PostId = CP.PostId
),
FinalMetrics AS (
    SELECT 
        PM.*,
        CASE 
            WHEN PM.CloseCount > 0 THEN 'Closed'
            ELSE 'Active'
        END AS Status,
        CASE 
            WHEN PM.OwnerReputation > 5000 THEN 'Veteran'
            WHEN PM.OwnerReputation BETWEEN 1000 AND 5000 THEN 'Established'
            ELSE 'Newcomer'
        END AS UserCategory
    FROM PostMetrics PM
)
SELECT 
    F.UserCategory,
    F.Status,
    F.Title,
    F.Score,
    F.CommentCount,
    F.CloseCount,
    F.Owner,
    F.OwnerReputation
FROM FinalMetrics F
WHERE F.Score > (
    SELECT AVG(Score) 
    FROM TopPosts 
)
ORDER BY F.Score DESC, F.CommentCount DESC
FETCH FIRST 10 ROWS ONLY;
