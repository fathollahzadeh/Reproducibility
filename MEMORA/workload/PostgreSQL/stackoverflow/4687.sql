
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END, 0) AS IsAccepted
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReOpenVotes,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.ReputationRank,
    PM.Title,
    PM.CommentCount,
    PM.UpVotes,
    PM.DownVotes,
    COALESCE(PHA.CloseVotes, 0) AS CloseVotes,
    COALESCE(PHA.ReOpenVotes, 0) AS ReOpenVotes,
    PHA.LastEditDate,
    PM.IsAccepted
FROM UserReputation U
JOIN PostMetrics PM ON U.UserId = PM.OwnerUserId
LEFT JOIN PostHistoryAggregates PHA ON PM.PostId = PHA.PostId
WHERE 
    U.Reputation > 1000 AND 
    PM.CommentCount > 5 AND 
    (PM.UpVotes - PM.DownVotes) > 10
ORDER BY U.ReputationRank, PM.Title;
