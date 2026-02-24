
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(MAX(PH.CreationDate), P.CreationDate) AS LastEdited,
        U.Reputation AS OwnerReputation
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) 
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, U.Reputation
),
ClosedPostStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.ViewCount,
        PS.CommentCount,
        PS.UpVoteCount,
        PS.DownVoteCount,
        PS.LastEdited,
        PS.OwnerReputation,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Open' 
        END AS PostStatus
    FROM PostStatistics PS
    LEFT JOIN PostHistory PH ON PS.PostId = PH.PostId 
                              AND PH.PostHistoryTypeId IN (10, 11)
    WHERE PS.CommentCount > 0 
),
SelectedUser AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        CASE WHEN EXISTS (
            SELECT 1 
            FROM ClosedPostStats CPS 
            WHERE CPS.OwnerReputation > UR.Reputation
        ) THEN 'Inferior' ELSE 'Superior' END AS ReputationRelation
    FROM UserReputation UR
    WHERE UR.Reputation > 1000
),
FinalResults AS (
    SELECT 
        CPS.*,
        SU.ReputationRelation
    FROM ClosedPostStats CPS
    JOIN SelectedUser SU ON CPS.OwnerReputation = SU.Reputation
)
SELECT 
    F.*,
    (CASE 
         WHEN F.PostStatus = 'Closed' THEN 'This post has been closed due to reasons outlined above.'
         ELSE 'This post is currently active and has received activity.' 
     END) AS StatusComment
FROM FinalResults F
ORDER BY F.LastEdited DESC, F.ViewCount DESC
LIMIT 100 OFFSET 0;
