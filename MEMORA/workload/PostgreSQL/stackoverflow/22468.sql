
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        P.Title IS NOT NULL
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Badges B
    WHERE 
        B.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        UserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CASE 
                        WHEN PH.PostHistoryTypeId = 10 THEN 'Closed: ' || (SELECT Name FROM CloseReasonTypes WHERE Id = PH.Comment::integer)
                        ELSE NULL 
                   END, ', ') AS CloseComments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13)  
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerReputation,
    UB.BadgeCount,
    COALESCE(CP.CloseComments, 'No closure comments') AS ClosureStatus,
    CASE 
        WHEN RP.Score > 100 THEN 'Highly Rated'
        WHEN RP.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rating' 
    END AS RatingCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges UB ON RP.OwnerReputation = UB.UserId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.PostRank <= 10
ORDER BY 
    RP.ViewCount DESC, RP.CreationDate ASC;
