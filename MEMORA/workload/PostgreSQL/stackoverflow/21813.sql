WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation > 1000 THEN 'High Reputation'
            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users U
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(AVG(P.Score), 0) AS AverageScore
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseActionCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (11, 13) THEN 1 END) AS ReopenActionCount
    FROM PostHistory PH
    GROUP BY PH.PostId
),
EnhancedPostData AS (
    SELECT 
        PM.PostId,
        U.DisplayName,
        U.Reputation,
        U.Reputation - 1000 AS ReputationAdjustment,
        COALESCE(Ms.CloseActionCount, 0) AS CloseCount,
        COALESCE(Ms.ReopenActionCount, 0) AS ReopenCount,
        CASE 
            WHEN PM.UpVotes - PM.DownVotes > 0 THEN 'Positive Interaction'
            WHEN PM.UpVotes - PM.DownVotes < 0 THEN 'Negative Interaction'
            ELSE 'Neutral Interaction'
        END AS InteractionStatus
    FROM PostMetrics PM
    JOIN Users U ON PM.OwnerUserId = U.Id
    LEFT JOIN PostHistorySummary Ms ON PM.PostId = Ms.PostId
),
FinalReport AS (
    SELECT 
        EPD.PostId,
        EPD.DisplayName,
        EPD.Reputation,
        EPD.ReputationAdjustment,
        EPD.CloseCount,
        EPD.ReopenCount,
        EPD.InteractionStatus,
        ROW_NUMBER() OVER (PARTITION BY EPD.InteractionStatus ORDER BY EPD.Reputation DESC) AS RankWithinCategory
    FROM EnhancedPostData EPD
)

SELECT 
    FR.*,
    CASE 
        WHEN FR.RankWithinCategory <= 5 THEN 'Top Performer'
        WHEN FR.RankWithinCategory BETWEEN 6 AND 10 THEN 'Average Performer'
        ELSE 'Needs Improvement'
    END AS PerformanceCategory
FROM FinalReport FR
WHERE FR.CloseCount > 0 OR FR.ReopenCount > 0
ORDER BY FR.Reputation DESC, FR.CloseCount DESC;
