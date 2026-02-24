WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (1, 2, 4, 5) THEN 1 END) AS EditCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(CASE WHEN B.UserId IS NOT NULL THEN 1 END) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
MaxStats AS (
    SELECT 
        MAX(CloseCount) AS MaxCloseCount,
        MAX(EditCount) AS MaxEditCount,
        MAX(UpvoteCount) AS MaxUpvoteCount,
        MAX(DownvoteCount) AS MaxDownvoteCount,
        MAX(BadgeCount) AS MaxBadgeCount
    FROM 
        PostStats
)
SELECT 
    PS.PostId,
    PS.CloseCount,
    PS.EditCount,
    PS.UpvoteCount,
    PS.DownvoteCount,
    PS.BadgeCount,
    CASE 
        WHEN PS.CloseCount = MS.MaxCloseCount THEN 'Highest Close Count' 
        ELSE NULL 
    END AS CloseCountRank,
    CASE 
        WHEN PS.EditCount = MS.MaxEditCount THEN 'Highest Edit Count' 
        ELSE NULL 
    END AS EditCountRank,
    CASE 
        WHEN PS.UpvoteCount = MS.MaxUpvoteCount THEN 'Highest Upvote Count' 
        ELSE NULL 
    END AS UpvoteCountRank,
    CASE 
        WHEN PS.DownvoteCount = MS.MaxDownvoteCount THEN 'Highest Downvote Count' 
        ELSE NULL 
    END AS DownvoteCountRank,
    CASE 
        WHEN PS.BadgeCount = MS.MaxBadgeCount THEN 'Highest Badge Count' 
        ELSE NULL 
    END AS BadgeCountRank
FROM 
    PostStats PS, MaxStats MS
ORDER BY 
    PS.PostId;