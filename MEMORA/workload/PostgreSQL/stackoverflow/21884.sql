WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.Score,
        RP.CreationDate,
        RP.PostRank,
        RP.UpvoteCount,
        RP.DownvoteCount,
        (RP.UpvoteCount - RP.DownvoteCount) AS NetScore,
        CASE 
            WHEN RP.Score > 10 THEN 'High Engagement'
            WHEN RP.Score BETWEEN 1 AND 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
),
FinalPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.Score,
        PD.CreationDate,
        PD.PostRank,
        PD.NetScore,
        PD.EngagementLevel,
        COALESCE(CP.CloseCount, 0) AS CloseCount
    FROM 
        PostDetails PD
    LEFT JOIN 
        ClosedPosts CP ON PD.PostId = CP.PostId
)
SELECT 
    F.*,
    CASE 
        WHEN F.CloseCount > 5 THEN 'Frequent Closure'
        WHEN F.CloseCount BETWEEN 1 AND 5 THEN 'Occasional Closure'
        ELSE 'No Closure'
    END AS ClosureBehavior,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = F.PostId)) AS BadgeCount
FROM 
    FinalPosts F
WHERE 
    F.NetScore > 0
ORDER BY 
    F.Score DESC, F.CreationDate ASC
LIMIT 10;