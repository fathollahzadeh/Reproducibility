
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
RecentBadges AS (
    SELECT 
        B.UserId,
        B.Name AS BadgeName,
        B.Class,
        RANK() OVER (PARTITION BY B.UserId ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Badges B
    WHERE 
        B.Class IN (1, 2) 
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName AS ClosedBy,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
)
SELECT 
    R.PostId,
    R.Title,
    R.Score,
    R.CreationDate,
    R.OwnerReputation,
    RB.BadgeName,
    RB.Class AS BadgeClass,
    CP.ClosedBy,
    CP.CloseReason
FROM 
    RankedPosts R
LEFT JOIN 
    RecentBadges RB ON R.OwnerUserId = RB.UserId AND RB.BadgeRank = 1 
LEFT JOIN 
    ClosedPosts CP ON R.PostId = CP.PostId
WHERE 
    R.Rank <= 5 
ORDER BY 
    R.PostId;
