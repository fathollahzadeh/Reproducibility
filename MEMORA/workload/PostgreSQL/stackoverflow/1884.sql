WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(DISTINCT PH.Id) FILTER (WHERE PH.PostHistoryTypeId = 11) AS ReopenCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.Score
),
HighScoredPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.TotalBounty,
        PS.CommentCount,
        PS.CloseCount,
        PS.ReopenCount,
        UR.ReputationRank
    FROM PostStatistics PS
    JOIN UserReputation UR ON PS.PostId IN (SELECT A.AcceptedAnswerId FROM Posts A WHERE A.PostTypeId = 1)
    WHERE PS.Score > 100
)
SELECT 
    HSP.PostId,
    HSP.Title,
    HSP.Score,
    HSP.TotalBounty,
    HSP.CommentCount,
    HSP.CloseCount,
    HSP.ReopenCount,
    UR.DisplayName,
    UR.Reputation AS CreatorReputation
FROM HighScoredPosts HSP
JOIN Users UR ON UR.Id IN (SELECT P.OwnerUserId FROM Posts P WHERE P.Id = HSP.PostId)
ORDER BY HSP.Score DESC, HSP.CommentCount DESC
LIMIT 10;