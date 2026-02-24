
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER(PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerReputation,
        COALESCE(AVG(V.BountyAmount) FILTER (WHERE V.VoteTypeId = 8), 0) AS AverageBounty,
        COALESCE(SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM RankedPosts RP
    LEFT JOIN Votes V ON RP.PostId = V.PostId
    LEFT JOIN Comments C ON RP.PostId = C.PostId
    LEFT JOIN Badges B ON RP.OwnerReputation >= B.Class * 100  
    WHERE RP.Rank <= 10  
    GROUP BY RP.PostId, RP.Title, RP.CreationDate, RP.Score, RP.ViewCount, RP.OwnerReputation
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        T.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes T ON CAST(PH.Comment AS INT) = T.Id
    WHERE PH.PostHistoryTypeId = 10
),
FinalStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.OwnerReputation,
        PS.AverageBounty,
        PS.CommentCount,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason
    FROM PostStatistics PS
    LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
)

SELECT 
    F.PostId,
    F.Title,
    F.CreationDate,
    F.Score,
    F.ViewCount,
    F.OwnerReputation,
    F.AverageBounty,
    F.CommentCount,
    F.CloseReason
FROM FinalStats F
WHERE 
    (F.Score > 100 OR F.ViewCount > 1000)
    AND F.OwnerReputation BETWEEN 100 AND 1000
ORDER BY F.Score DESC, F.ViewCount ASC;
