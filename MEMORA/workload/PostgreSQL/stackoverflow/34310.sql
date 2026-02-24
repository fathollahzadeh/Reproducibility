WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation,
        UR.Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserReputationCTE UR ON U.Reputation > UR.Reputation
),
RecentBadgeUsers AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        B.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.Score > 0
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CloseEventRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    R.BadgeCount,
    T.PostId,
    T.Title AS PostTitle,
    T.Score AS PostScore,
    CP.CreationDate AS CloseDate,
    CP.Comment AS CloseComment
FROM 
    Users U
LEFT JOIN 
    RecentBadgeUsers R ON U.Id = R.UserId
LEFT JOIN 
    TopPosts T ON U.Id = T.OwnerUserId AND T.PostRank = 1
LEFT JOIN 
    ClosedPosts CP ON T.PostId = CP.PostId AND CP.CloseEventRank = 1
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    R.BadgeCount DESC;