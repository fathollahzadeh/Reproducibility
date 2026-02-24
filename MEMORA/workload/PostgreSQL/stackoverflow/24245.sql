WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        Rank() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        MAX(P.CreationDate) AS LastActivity,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY MAX(P.CreationDate) DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId
),
UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PS.PostId,
        PS.PostTypeId,
        PS.UpVotes,
        PS.DownVotes,
        PS.CloseVotes,
        PS.LastActivity
    FROM Users U
    JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    WHERE PS.PostRank <= 3
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT PT.Name, ', ') AS HistoryTypes
    FROM PostHistory PH
    JOIN PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
    WHERE PH.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY PH.PostId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    COUNT(DISTINCT UP.PostId) AS TotalPosts,
    SUM(UP.UpVotes) AS TotalUpVotes,
    SUM(UP.DownVotes) AS TotalDownVotes,
    COALESCE(CP.HistoryCount, 0) AS ClosedPostHistoryCount,
    COALESCE(CP.HistoryTypes, 'No History') AS ClosedPostHistoryTypes,
    R.ReputationRank
FROM UserPosts UP
LEFT JOIN ClosedPosts CP ON UP.PostId = CP.PostId
JOIN UserReputation R ON UP.UserId = R.UserId
WHERE R.Reputation > 1000
GROUP BY UP.UserId, UP.DisplayName, CP.HistoryCount, CP.HistoryTypes, R.ReputationRank
ORDER BY TotalPosts DESC, R.ReputationRank ASC
LIMIT 10;