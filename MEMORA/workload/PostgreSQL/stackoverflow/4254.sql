WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId
),
PostHistoryCount AS (
    SELECT
        PH.PostId,
        COUNT(*) AS HistoryCount
    FROM PostHistory PH
    GROUP BY PH.PostId
),
RankedPosts AS (
    SELECT
        PS.PostId,
        PS.OwnerUserId,
        PS.TotalComments,
        PS.UpVotes,
        PS.DownVotes,
        PS.TotalScore,
        PS.AvgViewCount,
        COALESCE(PHC.HistoryCount, 0) AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.TotalScore DESC) AS PostRank
    FROM PostStatistics PS
    LEFT JOIN PostHistoryCount PHC ON PS.PostId = PHC.PostId
)
SELECT
    U.DisplayName,
    UR.Reputation,
    RP.PostId,
    RP.TotalComments,
    RP.UpVotes,
    RP.DownVotes,
    RP.TotalScore,
    RP.AvgViewCount,
    RP.HistoryCount,
    CASE 
        WHEN RP.PostRank <= 5 THEN 'Top Post'
        ELSE 'Regular'
    END AS PostCategory
FROM RankedPosts RP
JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
JOIN Users U ON UR.UserId = U.Id
WHERE U.Reputation > 1000 
  AND RP.HistoryCount > 5 
  AND RP.UpVotes - RP.DownVotes > 10
ORDER BY UR.Reputation DESC, RP.TotalScore DESC;
