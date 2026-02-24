WITH UserReputation AS (
    SELECT
        Id,
        Reputation,
        CASE
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
),
PostVoteStats AS (
    SELECT
        P.Id AS PostID,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
PostHistoryAggregates AS (
    SELECT
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors,
        MAX(PH.CreationDate) FILTER (WHERE PH.PostHistoryTypeId = 24) AS LastEditDate,
        MIN(PH.CreationDate) FILTER (WHERE PH.PostHistoryTypeId = 10) AS ClosedDate
    FROM PostHistory PH
    GROUP BY PH.PostId
),
TopPosts AS (
    SELECT
        P.Id AS PostID,
        P.Score,
        PH.EditCount,
        U.ReputationLevel
    FROM Posts P
    JOIN PostHistoryAggregates PH ON P.Id = PH.PostId
    JOIN UserReputation U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1 
      AND P.Score > 0
),
FinalResults AS (
    SELECT 
        T.PostID,
        T.Score,
        PH.TotalVotes,
        PH.Upvotes,
        PH.Downvotes,
        T.EditCount,
        T.ReputationLevel,
        CASE 
            WHEN T.EditCount > 2 THEN 'Frequently Updated'
            ELSE 'Rarely Updated'
        END AS UpdateFrequency,
        CASE 
            WHEN PH.TotalVotes IS NULL THEN 'No Votes' 
            ELSE CASE 
                WHEN PH.Upvotes > PH.Downvotes THEN 'Positive Reception'
                WHEN PH.Upvotes < PH.Downvotes THEN 'Negative Reception'
                ELSE 'Neutral Reception'
            END 
        END AS VoteReception
    FROM TopPosts T
    LEFT JOIN PostVoteStats PH ON T.PostID = PH.PostID
)
SELECT
    F.PostID,
    F.Score,
    F.TotalVotes,
    F.Upvotes,
    F.Downvotes,
    F.EditCount,
    F.ReputationLevel,
    F.UpdateFrequency,
    F.VoteReception,
    CASE WHEN F.Score IS NULL THEN 'Unknown Score' ELSE 'Score Available' END AS ScoreStatus
FROM FinalResults F
ORDER BY F.Score DESC NULLS LAST, F.TotalVotes DESC;