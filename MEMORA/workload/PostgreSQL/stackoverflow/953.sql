
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN PH.Id END) AS CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= '2023-01-01'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 1000
),
Combined AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.TotalBounty,
        PS.CommentCount,
        PS.CloseReopenCount,
        UR.DisplayName AS UserName,
        UR.Reputation,
        UR.ReputationRank
    FROM PostStats PS
    JOIN Users U ON PS.PostId = U.Id
    JOIN UserReputation UR ON U.Id = UR.UserId
    WHERE PS.RecentPostRank <= 10
)
SELECT 
    C.*,
    CASE WHEN C.CloseReopenCount > 0 THEN 'Closed/Reopened' ELSE 'Active' END AS PostStatus,
    CASE 
        WHEN C.ReputationRank BETWEEN 1 AND 10 THEN 'Top User'
        WHEN C.ReputationRank BETWEEN 11 AND 50 THEN 'Mid User'
        ELSE 'New User'
    END AS UserCategory
FROM Combined C
ORDER BY C.Reputation DESC, C.CreationDate DESC
LIMIT 100;
