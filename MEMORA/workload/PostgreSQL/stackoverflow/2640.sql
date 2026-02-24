
WITH UserReputation AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        P.OwnerUserId,
        PH.Comment AS CloseReason
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    WHERE P.PostTypeId = 1  
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostDetails AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(CP.ClosedDate, TIMESTAMP '2024-10-01 12:34:56') AS ClosedDate,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
        U.Reputation,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
    JOIN UserReputation U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
FinalResults AS (
    SELECT
        PD.Title,
        PD.Score,
        PD.ViewCount,
        PD.ClosedDate,
        PD.CloseReason,
        U.Reputation,
        UB.TotalBadges,
        RANK() OVER (PARTITION BY CASE 
                                      WHEN PD.ViewCount > 1000 THEN 'High'
                                      WHEN PD.ViewCount BETWEEN 100 AND 1000 THEN 'Medium'
                                      ELSE 'Low' 
                                   END 
                    ORDER BY PD.Score DESC) AS ScoreRank
    FROM PostDetails PD
    JOIN UserBadges UB ON PD.OwnerUserId = UB.UserId
    JOIN Users U ON PD.OwnerUserId = U.Id
)
SELECT 
    Title,
    Score,
    ViewCount,
    ClosedDate,
    CloseReason,
    Reputation,
    TotalBadges,
    ScoreRank
FROM FinalResults
WHERE ScoreRank <= 5 
ORDER BY ClosedDate DESC, Score DESC;
