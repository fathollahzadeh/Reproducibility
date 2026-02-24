
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::integer = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10  
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.OwnerDisplayName,
    RP.Upvotes,
    RP.Downvotes,
    RP.Rank,
    CP.CloseReason,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN CP.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    UserBadges UB ON RP.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = UB.UserId)
WHERE 
    RP.Rank <= 5  
ORDER BY 
    RP.CreationDate DESC;
