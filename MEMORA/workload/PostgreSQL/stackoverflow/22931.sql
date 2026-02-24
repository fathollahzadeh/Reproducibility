
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        P.PostTypeId,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBountyEarned
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON C.UserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id
    GROUP BY U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS ClosureCount,
        STRING_AGG(DISTINCT CT.Name, ', ') AS CloseReasonsList
    FROM PostHistory PH
    JOIN CloseReasonTypes CT ON PH.Comment::INTEGER = CT.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
),
PostMetrics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(CP.ClosureCount, 0) AS ClosureCount,
        COALESCE(CP.CloseReasonsList, 'None') AS CloseReasonsList,
        UA.PostCount AS UserPostCount,
        UA.CommentCount AS UserCommentCount,
        UA.TotalBountyEarned AS UserTotalBounty
    FROM RankedPosts RP
    JOIN Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN ClosedPosts CP ON RP.PostId = CP.PostId
    LEFT JOIN UserActivity UA ON U.Id = UA.UserId
    WHERE RP.ScoreRank <= 5 
),
FinalMetrics AS (
    SELECT 
        PM.*,
        CASE 
            WHEN PM.UserTotalBounty > 500 THEN 'High Bounty Earner'
            WHEN PM.UserTotalBounty BETWEEN 100 AND 500 THEN 'Medium Bounty Earner'
            ELSE 'Low Bounty Earner'
        END AS BountyCategory,
        CASE 
            WHEN PM.UserCommentCount = 0 THEN 'No comments'
            ELSE 'Active commenter'
        END AS CommenterStatus
    FROM PostMetrics PM
)

SELECT 
    FM.PostId,
    FM.Title,
    FM.Score,
    FM.OwnerDisplayName,
    FM.ClosureCount,
    FM.CloseReasonsList,
    FM.BountyCategory,
    FM.CommenterStatus
FROM FinalMetrics FM
ORDER BY FM.Score DESC, FM.ClosureCount ASC, FM.UserTotalBounty DESC;
